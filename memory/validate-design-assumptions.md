# Validate design assumptions before coding

When producing a plan or design document for any non-trivial software change, two explicit steps go into the plan **before** writing implementation code:

1. **Assumptions section.** Enumerate every assumption the design depends on — especially assumptions about third-party library behavior, framework contracts, message/frame ordering, side-effect semantics, and what events downstream consumers receive in what order. Phrase each assumption as a **falsifiable statement**, not a vague description.

2. **Validation section.** For each assumption, name a concrete way to verify it BEFORE coding the feature:
   - A unit test against the real library
   - A throwaway Python/JS script that exercises the precise behavior
   - A log capture from a running stack
   - A documentation citation with line numbers

   The validation must produce an **unequivocal yes/no answer**. Code-reading is necessary but not sufficient — library behavior often deviates from how it reads, especially around timing, queueing, and ordering.

   Use a subagent (Explore type) for the validation pass when the question requires reading multiple files or running scripts. Hand it the precise question phrased falsifiably.

## Why

In the resume-reading-after-interrupt feature (May 2026):

- The design assumed pipecat's TTS service would emit one `AggregatedTextFrame(SENTENCE)` per spoken sentence during a chunk push, in playback order.
- Code-reading suggested this was true (a comment literally said "emitted immediately before the TTSStartedFrame of the audio context it describes").
- In production it was false. `TTSSpeakFrame` bypasses sentence aggregation entirely. And for the LLM-streamed case, only the FIRST sentence of an LLM turn was timed correctly; sentences 2..N flushed downstream within ~10 ms of dispatch, before any audio played.
- The bug shipped to production. The user's resume always replayed from chunk start (or skipped ahead). Multiple round-trips wasted on diagnosis.
- A 6-line throwaway script (`SimpleTextAggregator.aggregate(multi_sentence_text)`) plus a careful read of the audio-context queue handling would have caught this in the planning phase.

## When this applies

- Anything touching pipeline / event ordering, third-party SDK behavior, framework hooks, async timing, or queueing semantics → **required**.
- Plans of any non-trivial size, including design docs reviewed in plan-mode → **required**.
- Tiny refactors, local edits, typo fixes, simple renames → skip.

## How to apply

Place the Assumptions and Validation sections **before** the implementation plan so reviewers can challenge the assumptions early. If a validation can't be defined for an assumption, treat the assumption as a known-unknown and call it out as a risk.

Sample structure:

```markdown
## Assumptions and validation

| Assumption | How it's validated |
|---|---|
| TTSTextFrame(WORD) arrives in real-time playback order | Read tts_service.py:1374-1381 and _add_word_timestamps:1154-1181; confirmed by Explore agent and pipecat docs |
| Cartesia emits word timestamps in our pipeline | cartesia/tts.py:458 hardcodes add_timestamps=True; receive loop at line 614-617 calls add_word_timestamps |
```
