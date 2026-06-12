# Pipecat Framework Notes

## Frame Routing: `push_frame` vs `queue_frame`

- **`push_frame(frame, direction)`** — Sends a frame to the **next** processor in the pipeline. Skips the calling processor's own `process_frame()`. Use this for passing frames along the pipeline from within `process_frame()`.
- **`queue_frame(frame, direction)`** — Injects a frame into **this** processor's input queue. The frame flows through the processor's `process_frame()` with full lifecycle (event handlers, metrics, ordering, interruption handling).

**When to use which:**
- Inside `process_frame()` to forward/emit frames → `push_frame()`
- External callers (e.g., LLM function handlers) injecting frames into a processor → `queue_frame()`

**Common mistake:** Calling `processor.push_frame(MyFrame(...))` from outside the pipeline (e.g., from an LLM function handler) — the frame goes to the next processor downstream, never reaching the processor's own `process_frame()`.

## Pipeline Architecture
- Processors are chained linearly: each has `_next` (downstream) and `_prev` (upstream)
- Each processor has an internal input queue with priority handling (SystemFrames get HIGH_PRIORITY)
- `FrameDirection.UPSTREAM` / `FrameDirection.DOWNSTREAM` controls routing direction

## TTS Service: which frames have real-time playback timing?

Only **two** frame types out of the TTS service are emitted in playback order, interleaved with audio. Everything else fires at queueing time, often before any audio plays.

| Frame | Emitted in playback order? | Notes |
|---|---|---|
| `TTSAudioRawFrame` | ✅ Yes | Pure audio bytes, with PTS. No text content. |
| `TTSTextFrame(aggregated_by=WORD)` | ✅ Yes | One per word. PTS anchored to first audio chunk. The canonical "currently spoken" signal. |
| `TTSTextFrame(aggregated_by=SENTENCE)` | ❌ No | Only emitted when `_push_text_frames=True` (Cartesia overrides to False). |
| `AggregatedTextFrame(SENTENCE)` | ❌ Mostly no | See gotcha below. |
| `TTSStartedFrame` / `TTSStoppedFrame` | ❌ No | Once per audio context, not per sentence. |

**Pipecat's own assistant-context aggregator uses `TTSTextFrame` to build the bot's message text** — confirmed by docs: "TTS outputs `TTSAudioRawFrame`s for playback, `TTSTextFrame`s representing the spoken text for context updates, and `TTSStartedFrame`/`TTSStoppedFrame` markers indicating speech boundaries."

## Gotcha #1: `AggregatedTextFrame(SENTENCE)` is NOT a reliable real-time signal

Reading the comment in `tts_service.py:1004` ("emitted immediately before the TTSStartedFrame of the audio context it describes") leads naturally to the wrong conclusion that it fires per-sentence in playback order. **It does not** for sentences 2..N within a single LLM turn.

What actually happens:
- **Sentence 1** of an LLM turn (or an isolated `TTSSpeakFrame`): the frame is put on the **serialization queue** (`tts_service.py:1014`). The serialization handler pops it and `push_frame`s it just before opening the audio context. ✅ Timed against audio.
- **Sentences 2..N** of the same LLM turn (because `reuse_context_id_within_turn=True` is the default): the frame goes through `append_to_audio_context(context_id, frame)` (`tts_service.py:1018`). The audio-context handler (`_handle_audio_context`, line 1366) reads queue items in order and `push_frame`s them as soon as it sees them. **Cartesia's audio chunks arrive over the websocket seconds later** and are appended afterward. So sentences 2..N flush downstream within ~10 ms of the chunk push, well before their audio plays.

Empirical confirmation: a real interrupt 10 s into a 4-sentence chunk had a snapshot showing all 4 sentences had already passed through a downstream tracker.

**If you need a "currently spoken" signal, use `TTSTextFrame(WORD)`, not `AggregatedTextFrame(SENTENCE)`.**

## Gotcha #2: `TTSSpeakFrame` bypasses the sentence aggregator entirely

When you push `TTSSpeakFrame(text="multi-sentence text")`, the TTS service does **not** route the text through `SimpleTextAggregator`. It wraps the entire text in a single `AggregatedTextFrame(text, AggregationType.SENTENCE)` (`tts_service.py:775-779`) — even if the text contains 10 sentences.

Implication: anything downstream that expects per-sentence frames per `TTSSpeakFrame` will see exactly one frame. This is a footgun for "track spoken sentence" use cases.

If you genuinely want per-sentence aggregation, push `TextFrame` (which goes through `_process_text_frame` → aggregator → emits one `AggregatedTextFrame(SENTENCE)` per sentence). But beware Gotcha #1 — those still aren't real-time.

Each `TTSSpeakFrame` also clears `_turn_context_id` and creates a fresh UUID for its own audio context (`tts_service.py:768-770`), so consecutive `TTSSpeakFrame`s in a row do NOT share a context.

## Gotcha #3: `reuse_context_id_within_turn` default and consequences

Default is `True` in `TTSService.__init__` (`tts_service.py:190`). Within an LLM-streamed turn (LLMFullResponseStartFrame…LLMFullResponseEndFrame), all aggregated sentences share **one** audio context = **one** `TTSStartedFrame` and **one** `TTSStoppedFrame` = **one** `BotStartedSpeaking` / `BotStoppedSpeaking` pair from `transport.output`.

Useful when you want sentence-level aggregation without N BotStopped events to coordinate. Combine with the `LLMFullResponseStart` wrap pattern.

## `SimpleTextAggregator` (the default text aggregator)

Lives at `pipecat/utils/text/simple_text_aggregator.py`. Used by every TTS service unless overridden.

- In `SENTENCE` mode (default): accumulates text char-by-char, looks for `[.!?]`, then waits for non-whitespace lookahead, then calls NLTK's `match_endofsentence` to confirm the boundary. This handles `Mr.`, `$29.`, etc.
- In `TOKEN` mode: yields each `aggregate(text)` call immediately (no buffering).
- `flush()` returns whatever's in the buffer at LLM-end / EndFrame time.

Module-level helpers in `pipecat.utils.string`: `match_endofsentence(text) -> int` (returns end-of-sentence index, 0 if none), `SENTENCE_ENDING_PUNCTUATION` constant.

## Cartesia-specific TTS notes

- `CartesiaTTSService` (websocket): `push_text_frames=False` (`cartesia/tts.py:336`). Only WORD-aggregated `TTSTextFrame`s are emitted (no SENTENCE-aggregated ones).
- `CartesiaHttpTTSService`: inherits the base default `push_text_frames=True`.
- `add_timestamps=True` is hardcoded in `_build_msg()` (`cartesia/tts.py:458`). Word-level timestamps are always requested from Cartesia's API — no opt-in needed.
- Word-text content (`_process_word_timestamps_for_language`, `cartesia/tts.py:419-452`):
  - Non-CJK: each word from Cartesia's tokenizer is its own `TTSTextFrame(WORD)`. Punctuation is typically a separate token (e.g. `Alice's.` → `["Alice's", "."]`).
  - Quoted strings: opening / closing quotes usually tokenize separately.
  - **Emoji-only segments produce NO word entries** — they are silently skipped by the tokenizer.
  - CJK: characters grouped into a single "word" with the first character's timestamp.

The Cartesia receive loop (around `cartesia/tts.py:614-617`) packages each word timestamp as `_WordTimestampEntry` and appends it to the audio context queue alongside `TTSAudioRawFrame`s. The serialization handler then pops them in playback order and turns them into `TTSTextFrame(WORD)` via `_add_word_timestamps` (`tts_service.py:1154-1181`), with PTS = `_initial_word_timestamp + ts_ns`.

## Tracking spoken position — there is no built-in processor

Pipecat ships no "current sentence" / "spoken position" processor as of 0.0.108. Build it yourself.

The reliable pattern:
1. Custom `FrameProcessor` placed downstream of the TTS service, upstream of `transport.output()`.
2. Listen for `TTSTextFrame` where `frame.aggregated_by == AggregationType.WORD`.
3. Buffer recent words in a `deque(maxlen=N)` (15 ≈ 5 s of speech is a useful default).
4. Snapshot the deque (or a phrase joined from it) at interrupt time, NOT at resume time — the live buffer is shared with whatever the bot says next (Q&A responses, transition phrases, emojis), and will be polluted by the time you read it on resume.

Multi-word phrase anchors are more findable in chunk text than single-word ones; common short words (`the`, `said`) collide. 5–10 words is usually unique.

## `LLMFullResponseStartFrame` / `LLMFullResponseEndFrame` wrap pattern

Useful when you want to inject text into the assistant context as if the LLM streamed it (e.g. `state_manager._assistant_says` for narrating book chunks):

```python
await self.push_frame(LLMFullResponseStartFrame(), FrameDirection.DOWNSTREAM)
await self.push_frame(TTSSpeakFrame(text=text), FrameDirection.DOWNSTREAM)
await self.push_frame(LLMFullResponseEndFrame(), FrameDirection.DOWNSTREAM)
```

The TTS service treats the wrap as one LLM turn. With `reuse_context_id_within_turn=True`, all per-sentence audio shares one context. The assistant aggregator (downstream of TTS) consumes the resulting `TTSTextFrame`s to build the message recorded in the LLM context.

If you push `TTSSpeakFrame` inside this wrap, you bypass sentence aggregation (Gotcha #2). If you push `TextFrame`, you get per-sentence aggregation (still subject to Gotcha #1 timing).

## Key Source Files (in site-packages/pipecat/)
- `processors/frame_processor.py` — Base `FrameProcessor` class with `push_frame` (line ~747) and `queue_frame` (line ~612)
- `pipeline/pipeline.py` — `Pipeline`, `PipelineSource`, `PipelineSink`
- `processors/aggregators/llm_context.py` — `LLMContext` for shared conversation state
- `services/tts_service.py` — Base TTS service. Critical methods: `process_frame` (line ~705), `_push_tts_frames` (line ~952), `_handle_audio_context` (line ~1360), `_add_word_timestamps` (line ~1154).
- `services/cartesia/tts.py` — Cartesia override: `_push_text_frames=False`, `add_timestamps=True`, word-timestamp processing.
- `utils/text/simple_text_aggregator.py` — Default sentence aggregator with NLTK-based boundary detection.
- `utils/string.py` — `match_endofsentence`, `SENTENCE_ENDING_PUNCTUATION`.
- `frames/frames.py` — All frame definitions, including `TTSTextFrame`, `AggregatedTextFrame`, `TTSAudioRawFrame`, `TTSStartedFrame`, etc.
- `utils/text/base_text_aggregator.py` — `AggregationType` enum (`WORD`, `SENTENCE`, `TOKEN`).
