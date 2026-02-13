# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in toocan-app repository.

## Project Overview

.. add description here ...

## Common Commands


### Backend

... TODO: update: we now use ty and prek please reflect that in the commands below and also add a section for front-end commands
```bash

# Install pre-commit hooks
uv run prek install ??< check this one

# Run all tests
uv run pytest

# Run a single test file
uv run pytest tests/test_name.py

# Run a specific test
uv run pytest tests/test_name.py::test_function_name


# Lint and format check
uv run ruff check
uv run ruff format --check

# Update dependencies (after editing pyproject.toml)
uv lock && uv sync
```

## Architecture


### Pipecat pipeline architecture and patterns (bot.py)


#### Frame-Based Pipeline Processing

All data flows as **Frame** objects through a pipeline of **FrameProcessors**:

```
[Processor1] → [Processor2] → ... → [ProcessorN]
```

**Key components:**

- **Frames** (`src/pipecat/frames/frames.py`): Data units (audio, text, video) and control signals. Flow DOWNSTREAM (input→output) or UPSTREAM (acknowledgments/errors).

- **FrameProcessor** (`src/pipecat/processors/frame_processor.py`): Base processing unit. Each processor receives frames, processes them, and pushes results downstream.

- **Pipeline** (`src/pipecat/pipeline/pipeline.py`): Chains processors together.

- **ParallelPipeline** (`src/pipecat/pipeline/parallel_pipeline.py`): Runs multiple pipelines in parallel.

- **Transports** (`src/pipecat/transports/`): Transports are frame processors used for external I/O layer (Daily WebRTC, LiveKit WebRTC, WebSocket, Local). Abstract interface via `BaseTransport`, `BaseInputTransport` and `BaseOutputTransport`.

- **Pipeline Task (`src/pipecat/pipeline/task.py`)**: Runs and manages a pipeline. Pipeline tasks send the first frame, `StartFrame`, to the pipeline in order for processors to know they can start processing and pushing frames. Pipeline tasks internally create a pipeline with two additional processors, a source processor before the user-defined pipeline and a sink processor at the end. Those are used for multiple things: error handling, pipeline task level events, heartbeat monitoring, etc.

- **Pipeline Runner (`src/pipecat/pipeline/runner.py`)**: High-level entry point for executing pipeline tasks. Handles signal management (SIGINT/SIGTERM) for graceful shutdown and optional garbage collection. Run a single pipeline task with `await runner.run(task)` or multiple concurrently with `await asyncio.gather(runner.run(task1), runner.run(task2))`.

- **Services** (`src/pipecat/services/`): 60+ AI provider integrations (STT, TTS, LLM, etc.). Extend base classes: `AIService`, `LLMService`, `STTService`, `TTSService`, `VisionService`.

- **Serializers** (`src/pipecat/serializers/`): Convert frames to/from wire formats for WebSocket transports. `FrameSerializer` base class defines `serialize()` and `deserialize()`. Telephony serializers (Twilio, Plivo, Vonage, Telnyx, Exotel, Genesys) handle provider-specific protocols and audio encoding (e.g., μ-law).

- **RTVI** (`src/pipecat/processors/frameworks/rtvi.py`): Real-Time Voice Interface protocol bridging clients and the pipeline. `RTVIProcessor` handles incoming client messages (text input, audio, function call results). `RTVIObserver` converts pipeline frames to outgoing messages: user/bot speaking events, transcriptions, LLM/TTS lifecycle, function calls, metrics, and audio levels.

- **Observers** (`src/pipecat/observers/`): Monitor frame flow without modifying the pipeline. Passed to `PipelineTask` via the `observers` parameter. Implement `on_process_frame()` and `on_push_frame()` callbacks.

#### Important Patterns when touching Pipecat Pipeline
e.g. when creating custom frame processors, observers etc...

- **Context Aggregation**: `LLMContext` accumulates messages for LLM calls; `UserResponse` aggregates user input

- **Turn Management**: Turn management is done through `LLMUserAggregator` and
`LLMAssistantAggregator`, created with `LLMContextAggregatorPair`

- **User turn strategies**: Detection of when the user starts and stops speaking is done via user turn start/stop strategies. They push `UserStartedSpeakingFrame` and `UserStoppedSpeakingFrame` respectively.

- **Interruptions**: Interruptions are usually triggered by a user turn start strategy (e.g. `VADUserTurnStartStrategy`) but they can be triggered by other processors as well, in which case the user turn start strategies don't need to. An `InterruptionFrame` carries an optional `asyncio.Event` that is set when the frame reaches the pipeline sink. If a processor stops an `InterruptionFrame` from propagating downstream (i.e., doesn't push it), it **must** call `frame.complete()` to avoid stalling `push_interruption_task_frame_and_wait()` callers.

- **Uninterruptible Frames**: These are frames that will not be removed from internal queues even if there's an interruption. For example, `EndFrame` and `StopFrame`.

- **Events**: Most classes in Pipecat have `BaseObject` as the very base class. `BaseObject` has support for events. Events can run in the background in an async task (default) or synchronously (`sync=True`) if we want immediate action. Synchronous event handlers need to execute fast.

- **Async Task Management**: Always use `self.create_task(coroutine, name)` instead of raw `asyncio.create_task()`. The `TaskManager` automatically tracks tasks and cleans them up on processor shutdown. Use `await self.cancel_task(task, timeout)` for cancellation.

- **Error Handling**: Use `await self.push_error(msg, exception, fatal)` to push errors upstream. Services should use `fatal=False` (the default) so application code can handle errors and take action (e.g. switch to another service).

### Key Directories

TODO: add key project directories here with a description e.g.

| Directory                 | Purpose                                            |
|---------------------------|----------------------------------------------------|
| `src/pipecat/frames/`     | Frame definitions (100+ types)                     |
| `src/pipecat/processors/` | FrameProcessor base + aggregators, filters, audio  |

## Code Style

- **Docstrings**: ..

TODO: add more ?? complete this section


## System Environment

- **Shell**: zsh (macOS default) - fish is NOT installed
- **Terminal**: Ghostty
- **Platform**: macOS Darwin

## Node.js Version Management

This system uses **nvm** for Node version management. The shell is configured to automatically use the correct Node version, so no manual nvm activation is needed.

## Cursor Rules

**IMPORTANT**: When working in any project, check for and read `.cursor/rules/*.mdc` files if they exist. These contain project-specific coding standards that MUST be followed.

Common rule files:
- `workflow.mdc` - Development workflow requirements
- `standards.mdc` - General coding guidelines
- `svelte.mdc` - Svelte/frontend conventions
- `typescript.mdc` - TypeScript/testing patterns

## Code Style Preferences

### General
- Arrow functions ONLY: `const fn = () => {}`
- Always use `await`, never `.then()`
- Avoid nested code - use early returns
- Max 200 lines per file preferred
- Clean up unused code completely

### Early Returns Pattern
```typescript
// GOOD: Flat code with early returns
if (error) {
  console.error(error);
  return;
}
// main logic here

// BAD: Nested code
if (!error) {
  // main logic here
}
```

## Package Managers

| Project Type | Package Manager | Install Command |
|--------------|-----------------|-----------------|
| Node.js/TypeScript | pnpm | `pnpm install` |
| Python | uv | `uv sync` |

## Worktree Docker Compose

When working in a git worktree, use a unique `COMPOSE_PROJECT_NAME` to avoid port collisions with other worktrees.

**Starting the dev stack for a worktree:**
```bash
# Stop any other docker compose projects first to avoid port collisions

# Install dependencies (run once or when package.json changes)
COMPOSE_PROJECT_NAME=qz-<ticket> docker compose run --rm client pnpm install

# Start the dev stack
COMPOSE_PROJECT_NAME=qz-<ticket> docker compose up -d
```

**Stopping the dev stack:**
```bash
COMPOSE_PROJECT_NAME=qz-<ticket> docker compose down
```

Replace `<ticket>` with the ticket/branch identifier (e.g., `qz-pro456`).

## Quality Checks

Always run quality checks before committing:

**Frontend (SvelteKit)**:
```bash
cd client
pnpm github-checks  # lint + test + types
```

**Backend (Python)**:
```bash
cd server
ruff check && ruff format && pytest
```
