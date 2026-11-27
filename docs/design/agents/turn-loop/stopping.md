# Stopping

How you stop an agent with the stop key, a turn count, or spending limits, and how it resumes. Part of the [turn loop](README.md).

Every model call costs money, so you can stop the agent at any moment, and spending limits stop it for you. A run is one start of the bridge.

The bridge stops a run in three ways:

- **Stop key.** Press Ctrl+C in the bridge's console. The bridge aborts the model call in progress, waits for the Lua command in progress, logs `stopped`, and exits with code 0. It sends no end turn, so the game waits on the agent's turn.

  Each running turn logs `turn_cancelled`, as a turn does when a [game loads](../game-load.md), and no new turn starts. A second Ctrl+C exits at once with code 1.
- **Turn count.** `--turns <n>` stops the bridge the same way after the agent ends its n-th turn. Live tests use it to play a fixed number of turns.

  The count covers every agent's turns since the bridge started. A turn ended with force counts, and a skipped or stopped turn doesn't. With `--mcp`, no agent turn ends, so the bridge warns that `--turns` does nothing.
- **Spending limits.** `limits` in the [config file](../../core/settings.md) caps the tokens of model calls, their cost in dollars, or both, for each turn and each run. A cost limit needs the model's price in the config file.

  A turn that reaches its limit ends like a turn that hits any other limit. A run that reaches its limit stops as the stop key does.

To resume, start the bridge again. [Resync on connect](../../core/bridge.md) prints `AGENT_TURN` for the active turn, and the agent reads the state, which already holds the actions it took before the stop.

The limits start blank, so there is no limit until you set one, and the bridge warns when none is set. The smoke test's measured tokens and cost per turn are a guide.

## Decisions

| Decision | Reason |
| --- | --- |
| The stop key aborts the model call and sends no end turn | Stopping costs nothing more, and the turn resumes from the state when the bridge starts again |
| The stop key cancels a turn the way a game load does | Both end the turn with no end turn and wait for the Lua command in progress, so they share one abort signal, and its reason picks the log text |
| `--turns` counts every agent's turns, not each agent's own | One agent plays in phase 2, and a live test wants a fixed amount of play, so one count stops one run |
| A second Ctrl+C exits with code 1 | It may cut off a Lua command, so a script that starts the bridge can tell it apart from a clean stop |
| The run spending limit counts one start of the bridge, not one game | A game outlives restarts, so a total per game needs stored totals. Each call's cost is already in the log |
| Spending limits in tokens, dollars, or both, blank to start | Users pay in dollars, but neither the AI SDK nor the providers' model lists give a price, so a dollar limit needs a price that the user enters. A token limit needs nothing |
