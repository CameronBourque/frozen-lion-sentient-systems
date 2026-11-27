# Phase 3: Bridge GUI

This phase gives the bridge a window, so you set up and control an agent without a terminal. The console stays as a fallback for headless runs, on the same code as the window. It is about the bridge only. The panels and options in the game come in later phases.

**Gate.** You set up a single-agent game, start it, stop it, and resume it from the bridge window, without a terminal.

## Scope

- A design doc for the bridge GUI in [core/](../../design/core/README.md), with the choice of toolkit
- One shared control layer for setup and control, which both the window and the console call, so each adds only its own way to show and ask
- The setup screens: the run mode, the provider, the [model picker](../../design/core/picker.md), the API key, and the ChatGPT sign-in, in place of the console prompts
- The opt-in to save plan tokens, which [subscription-token.md](../../design/core/subscription-token.md#decisions) leaves to a GUI
- A start button that also resumes. When a run stops, the bridge process stays open, and start begins a new run from the turn in progress, as [stopping.md](../../design/agents/turn-loop/stopping.md) describes for a restart today
- A stop button in place of the stop key, and settings for the turn count and the spending limits. Decide whether a run's spending limit counts one start of the run or one start of the bridge
- A status view: the turn, the agent's actions, the cost so far, and the newest log lines
- A console redesign on the shared layer: keys that run the window's buttons and switch its toggles, such as start, stop, and the limits, in place of the prompts that only the console has

Design: [core/run-modes.md](../../design/core/run-modes.md), [core/picker.md](../../design/core/picker.md), [core/settings.md](../../design/core/settings.md), [core/subscription-token.md](../../design/core/subscription-token.md), [agents/turn-loop/stopping.md](../../design/agents/turn-loop/stopping.md), [core/logs.md](../../design/core/logs.md).

## Steps

Not broken down yet. When it is, the scope items become steps, and we remove this list.
