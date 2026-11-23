# Claude runner

Add the Claude Agent SDK runner to the **Agent SDK** run mode, behind a flag that stays off until Anthropic approves. The design is in [run-modes.md](../../design/core/run-modes.md#runners). Part of [phase 2](README.md).

## Tasks

1. **Runner.** Move the agent loop behind `AgentRunner` in `src/agents/runner.ts`, with no change in how a turn plays. Commit: `refactor(core): run turns through an agent runner`.
2. **Tools check.** Run the [plan-access.md](../../findings/plan-access.md#method) method for question 3 with `ANTHROPIC_API_KEY` set, so no plan login is used. Record the result. Commit: `docs: record the Claude Agent SDK tools check`.
3. **Claude runner.** Add the runner that calls `query()` with the options in [run-modes.md](../../design/core/run-modes.md#claude-runner). Test it with a fake `query()` that calls tools, calls `end_turn`, and never answers. Commit: `feat(core): run Claude turns through the Agent SDK`.
4. **Flag.** Add `CLAUDE_AGENT_SDK_ENABLED`, set to `false`, in `src/model/providers/anthropic.ts`. While it is false, Anthropic's `modes` has no `agent-sdk` entry.

   With the flag on, the picker checks the login and lists the models from `supportedModels()`. Commit: `feat(core): add Claude to the agent SDK mode behind a flag`.

## Done when

All of these hold:

- With the flag off, **Agent SDK** reads `(not available yet)`.
- In a local build with the flag on and `ANTHROPIC_API_KEY` set, the bridge plays one agent turn in a running game, and the log shows each tool call with its `reason`.
- In that build, the SDK lists no built-in tool, and Ctrl+C during the turn exits within 5 seconds.

## Record

- The answer to question 3, in [plan-access.md](../../findings/plan-access.md).
- `AgentRunner`, in [turn-loop.md](../../design/agents/turn-loop.md).
- Any option that differs from the design, in [run-modes.md](../../design/core/run-modes.md#claude-runner).
