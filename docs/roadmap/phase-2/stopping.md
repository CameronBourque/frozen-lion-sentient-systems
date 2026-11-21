# Stopping and spending limits

Add the stop key, the turn count, and the spending limits, so an agent never spends more than you allow. The design is in [turn-loop.md](../../design/agents/turn-loop.md#stopping). Part of [phase 2](README.md).

## Tasks

1. **Stop key.** Handle Ctrl+C in `src/main.ts`. Abort the model call in progress with an `AbortSignal`, wait for the Lua command in progress, log `stopped` at the warn level, and exit with code 0.

   A second Ctrl+C exits at once. Test it with a mock model that never answers. Commit: `feat(core): stop the agent on Ctrl+C`.
2. **Turn count.** Add `--turns <n>`, which stops the bridge the same way after the agent ends its n-th turn. Commit: `feat(core): stop after a number of agent turns`.
3. **Spending limits.** Add `tokensPerTurn`, `tokensPerRun`, `costPerTurn`, and `costPerRun` to `limits` in the config file, all blank to start, so there is no limit until you set one. A token limit counts input and output tokens. Sum each call's tokens and cost from the [model client](../../design/core/model-client.md) usage.

   A cost limit needs `model.price`, so a cost limit with no price logs a warning when the bridge starts. With no spending limit set, the bridge logs a warning when it starts.

   A turn at its limit ends with `force`, as the other turn limits do. A run at its limit stops as the stop key does, and logs the run's total cost. Commit: `feat(core): add spending limits`.

## Done when

All of these hold in a running game:

- Ctrl+C during a model call exits within 5 seconds and sends no end turn.
- A restart of the bridge after that stop resumes the same turn.
- `--turns 2` exits after the second agent turn ends.
- With `tokensPerRun: 1000`, the bridge stops after the first model call and logs the total tokens.
- With `costPerRun: 0.01` and a price set, the bridge stops after the first model call and logs the total cost.

## Record

- The `limits` fields and their defaults, in [settings.md](../../design/core/settings.md).
- Whether the restart resumes the turn as [turn-loop.md](../../design/agents/turn-loop.md#stopping) says. Fix the section if it doesn't.
