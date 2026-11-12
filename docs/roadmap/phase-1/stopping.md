# Stopping and spending limits

Add the stop key, the turn count, and the spending limits, so an agent never spends more than you allow. The design is in [turn-loop.md](../../design/agents/turn-loop.md#stopping). Part of [phase 1](README.md).

## Tasks

1. **Stop key.** Handle Ctrl+C in `src/main.ts`. Abort the model call in progress with an `AbortSignal`, wait for the Lua command in progress, log `stopped` at the warn level, and exit with code 0.

   A second Ctrl+C exits at once. Test it with a mock model that never answers. Commit: `feat(core): stop the agent on Ctrl+C`.
2. **Turn count.** Add `--turns <n>`, which stops the bridge the same way after the agent ends its n-th turn. Commit: `feat(core): stop after a number of agent turns`.
3. **Spending limits.** Add `costPerTurn` and `costPerRun` to `limits` in the config file, with starting defaults of 0.50 and 5.00 US dollars. Sum each call's cost from the [model client](model-client.md) usage.

   A turn at its limit ends with `force`, as the other turn limits do. A run at its limit stops as the stop key does, and logs the run's total cost. Commit: `feat(core): add spending limits`.

## Done when

All of these hold in a running game:

- Ctrl+C during a model call exits within 5 seconds and sends no end turn.
- A restart of the bridge after that stop resumes the same turn.
- `--turns 2` exits after the second agent turn ends.
- With `costPerRun: 0.01`, the bridge stops after the first model call and logs the total cost.

## Record

- The `limits` fields and their defaults, in [settings.md](../../design/core/settings.md).
- Whether the restart resumes the turn as [turn-loop.md](../../design/agents/turn-loop.md#stopping) says. Fix the section if it doesn't.
