# Core mod actions

How the core mod runs actions through the game's own request functions, and the reasons a failed action returns. Part of the [core mod](../README.md).

## Action API

Each action wraps the request function the game's own UI calls, and the game checks legality. A failed action returns its reason. The reason comes from the game's check where it gives one, and from the API's own messages for common cases.

The game's UI Lua files ship as plain text and show which call each screen makes. See the [action findings](../../../../findings/actions/move-unit.md).

| File | Covers |
| --- | --- |
| [units.md](units.md) | Moves, unit orders, stances, attacks, upgrades, formations, and air and transport |
| [unit-jobs.md](unit-jobs.md) | Builder jobs, adding production, great people, and religious units |
| [cities.md](cities.md) | Production, purchases, trade routes, and spy missions |

### Results

Every action returns the same JSON, `{ "ok": true }` or `{ "ok": false, "reason": "<text>" }`, with no `reason` when it worked. `SentientSystems_RunAction(name, action)` in `Scripts/Actions/SentientSystemsCore_Actions.lua` builds it, and the UI script loads the file.

The action is a function that returns nothing when it worked and the reason as text when it failed. A Lua error in it comes back as a failure with the error's first line, so the bridge always reads a reason.

The bridge reads the result through the stash. `sendAction` in [actions.ts](../../../../../packages/core/bridge/src/actions/actions.ts) turns a failure to reach the game, or a reply that isn't a result, into a failed result with that error as the reason. The shape is the schema in the same file.

## Decisions

| Decision | Reason |
| --- | --- |
| Every failed action returns a reason | The agent can decide again instead of repeating a mistake |
