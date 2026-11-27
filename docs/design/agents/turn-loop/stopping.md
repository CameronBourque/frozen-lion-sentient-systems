# Stopping

How you stop an agent with the stop key, a turn count, or spending limits, and how it resumes. Part of the [turn loop](README.md).

Every model call costs money, so you can stop the agent at any moment, and spending limits stop it for you. A run is one start of the bridge.

The bridge stops a run in three ways:

- **Stop key.** Press Ctrl+C in the bridge's console. The bridge aborts the model call in progress, waits for the Lua command in progress, logs `stopped`, and exits. It sends no end turn, so the game waits on the agent's turn. A second Ctrl+C exits at once.
- **Turn count.** `--turns <n>` stops the bridge the same way after the agent ends its n-th turn. Live tests use it to play a fixed number of turns.
- **Spending limits.** `limits` in the [config file](../../core/settings.md) caps the tokens of model calls, their cost in dollars, or both, for each turn and each run. A cost limit needs the model's price in the config file.

  A turn that reaches its limit ends like a turn that hits any other limit. A run that reaches its limit stops as the stop key does.

To resume, start the bridge again. [Resync on connect](../../core/bridge.md) prints `AGENT_TURN` for the active turn, and the agent reads the state, which already holds the actions it took before the stop.

The limits start blank, so there is no limit until you set one, and the bridge warns when none is set. The smoke test's measured tokens and cost per turn are a guide.

## Decisions

| Decision | Reason |
| --- | --- |
| The stop key aborts the model call and sends no end turn | Stopping costs nothing more, and the turn resumes from the state when the bridge starts again |
| The run spending limit counts one start of the bridge, not one game | A game outlives restarts, so a total per game needs stored totals. Each call's cost is already in the log |
| Spending limits in tokens, dollars, or both, blank to start | Users pay in dollars, but neither the AI SDK nor the providers' model lists give a price, so a dollar limit needs a price that the user enters. A token limit needs nothing |
