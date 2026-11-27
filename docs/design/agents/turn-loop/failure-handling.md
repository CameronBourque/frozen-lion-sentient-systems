# Failure handling

How the turn loop limits retries, actions, and time in a turn, and ends a stuck turn with `force`. Part of the [turn loop](README.md).

When an action fails, the agent gets the reason and decides again. The loop limits retries per action, actions per turn, and time per turn. When the loop hits a limit, it ends the turn with `force`, which skips the blockers that are left, so one stuck turn cannot stop a game.

The forced end logs `turn_forced` as a warning, with the limit's name in `limit`. It then logs the blockers it skipped as one `blockers_skipped` warning, and the units that needed orders as one `units_skipped` warning, from the list that the [end turn action](../../core/mod/actions/turn.md) returns. An empty list logs nothing.

A forced end can still fail, such as with a deal waiting or a game that doesn't answer. The turn then stops and logs `turn_stopped`, with the limit's reason and the failure, and the next signal plays it again.

`limits` in the [config file](../../core/settings.md) sets the three limits:

| Field | Default | What it counts |
| --- | --- | --- |
| `retriesPerAction` | `3` | Failed actions in a row, and replies with no tool call. An action that goes through resets the count. A fourth failure in a row ends the turn with force at the default |
| `actionsPerTurn` | `250` | Calls to the action tools, the tools with a `reason` field, whether they fail or go through. Tools that read the state, look up rules, or change memory don't count |
| `turnMinutes` | `15` | Time from the first model call of the turn. The limit aborts the model call in progress |

The token and cost limits for each turn end the turn the same way. They are in [stopping.md](stopping.md), with the run limits that stop the bridge.

A blocked `end_turn` counts as a failed action, and one that goes through ends the turn even at the actions limit. A [game load](../game-load.md) still cancels the turn, and sends no end turn.

## Decisions

| Decision | Reason |
| --- | --- |
| Retry, action, and time limits per turn | One stuck turn cannot stop a game |
| A turn limit ends the turn with `force`, and a failed model call stops it | A stuck model at a limit would otherwise hold the game for every player. A model that can't be called would only force turn after turn with no play, as [subscription-token.md](../../core/subscription-token.md#decisions) says of a usage limit |
| A forced end logs the blockers it skipped on one line, and the units on another | A forced turn can skip research or production, and the log shows which, so a review finds what the model couldn't resolve. A line per unit would bury the turn's other lines in a large empire |
| A reply with no tool call gets a nudge, and counts as a failure | A model that only writes may still act when asked, and one that only talks stops after a few replies |
| Only the action tools count against the actions limit | A turn reads the state and the rules many times between actions |
| Failures in a row count, and a success resets them | A model that tries a new input after each failure is still stuck |
| The time limit aborts the model call in progress | A long reasoning call would otherwise run a whole call past the limit |
| `actionsPerTurn` defaults to `250` | A late-game turn moves many units and runs many cities. A limit that scales with the empire waits for a measured late-game turn |
