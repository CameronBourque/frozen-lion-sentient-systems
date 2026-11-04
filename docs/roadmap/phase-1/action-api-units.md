# Action API: units

Add the action result format and the actions for units: move, stance, found city, improve, pillage, and attack. Each action wraps the request function the game's own UI calls, and a failed action returns its reason. Part of [phase 1](README.md).

These actions also resolve the three unit blockers (`ENDTURN_BLOCKING_UNITS`, `ENDTURN_BLOCKING_UNIT_NEEDS_ORDERS`, and `ENDTURN_BLOCKING_STACKED_UNITS`), which have no screen. See [end-turn blockers](../../findings/game-state.md#end-turn-blockers).

## Tasks

1. **Result format.** Add `Scripts/SentientSystemsCore_Actions.lua`, imported into the UI state. Each action returns JSON `{ ok, reason }`. The reason comes from the game's check where it gives one, and from the API's own message otherwise. Add `src/actions.ts` with the result schema and the helper that sends an action to the UI state. Create `findings/game-actions.md` for the action calls, and move the move and end turn sections out of `game-api.md` into it. Commit: `feat(core): add the action result format`.
2. **Move.** Add `SentientSystems_MoveUnit(playerID, unitID, x, y)` from the [move path](../../findings/game-actions.md#moving-a-unit). Check the target against the [reachable tiles](../../findings/game-actions.md#checking-a-move) and return a reason when it isn't one. For a multi-turn move, let the game's pathfinding plan the route. Add `moveUnit` to `src/actions.ts`. Commit: `feat(core): add the move action`.
3. **Stance, delete, and promote.** Add `SentientSystems_UnitAction(playerID, unitID, action, x, y)` for fortify, sleep, skip, delete, and promote. Read the calls from `UnitPanel.lua`. Add `unitAction` to `src/actions.ts`. Commit: `feat(core): add unit stance, delete, and promote actions`.
4. **Found city, improve, and pillage.** Add found city, build improvement, and pillage to `SentientSystems_UnitAction`. Check the tile with `CanStartOperation` and return the failure reasons. Commit: `feat(core): add the found city, improve, and pillage actions`.
5. **Attack.** Add melee, ranged, city, and air attacks to `SentientSystems_UnitAction`. Decide the rule for a move that would declare war, which the UI confirms in a dialog. Commit: `feat(core): add the attack action`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a move into deep water, a city too close to another city, or an attack on a unit out of range.

## Record

- Each request function, its Lua state, and its result, in `findings/game-actions.md`.
- The result format and the reasons, in [in-game-lua.md](../../design/core/in-game-lua.md).
- The parts of an action, in a new `## Parts of an action` table in the [core README](../../../packages/core/README.md): the Lua function in `Scripts/SentientSystemsCore_Actions.lua`, its Lua test, the typed function in `src/actions.ts`, and its test with a fake client. Each later action step adds its rows.
