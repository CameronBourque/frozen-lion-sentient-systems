# Game actions

Status: open. Moving a unit, checking its route, the unit orders, and ending the turn are confirmed in a running game. The other actions are not yet looked at.

The game calls the action API wraps, with the Lua state each runs in and where we found each call. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](game-api.md). The core mod's result format is in [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. What failure reasons do `CanStartOperation` and `CanStartCommand` give for found city, build improvement, pillage, and the attacks? The reasons for a move are checked by hand, as the move check below says.

## What we know now

### Moving a unit

The UI's move path is `MoveUnitToPlot` in `Base/Assets/UI/Civ6Common.lua`, lines 102 to 169. Confirmed in files. The same calls move a unit when the bridge sends them to `SentientSystemsCore_UI`, if the target is in the unit's [reachable tiles](#checking-a-move). Confirmed on Windows on 2026-10-23. The core of the path:

```lua
local tParameters = {};
tParameters[UnitOperationTypes.PARAM_X] = plotX;
tParameters[UnitOperationTypes.PARAM_Y] = plotY;
tParameters[UnitOperationTypes.PARAM_MODIFIERS] =
	UnitOperationMoveModifiers.ATTACK + UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION;
if UnitManager.CanStartOperation(kUnit, UnitOperationTypes.MOVE_TO, nil, tParameters) then
	UnitManager.RequestOperation(kUnit, UnitOperationTypes.MOVE_TO, tParameters);
end
```

Notes on that path:

- It checks for war first, with `CombatManager.IsAttackChangeWarState`. If the move would start a war, the UI opens a confirmation dialog instead of moving (lines 110 to 127). Our action API needs its own rule for this case.
- Air units use `AIR_ATTACK` or `DEPLOY` instead (lines 139 to 145).
- It tries `RANGE_ATTACK`, `COASTAL_RAID`, and `SWAP_UNITS` before a plain `MOVE_TO` (lines 148 to 163). One click in the UI can mean one of several operations.
- It skips the request when the target is the unit's own tile, because otherwise the next unit gets auto-selected (lines 156 to 159).

civ6-mcp moves a unit with a shorter path than the UI, in [`build_move_unit`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L189). Unconfirmed, used by civ6-mcp:

- It checks `unit:GetMovesRemaining()`, then calls `UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, true)` with no target parameters.
- It adds the `ATTACK` modifier only when another player's unit is on the target tile.
- After `RequestOperation`, it reads the unit's position again in a gameplay state, in [`build_unit_position_query`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L235). If the unit didn't reach the target, that query checks the target tile for water, mountains, and foreign borders to explain why.

The game's Lua also uses these calls: `CanStartCommand` and `RequestCommand` for unit commands, `GetOperationTargets`, `GetCommandTargets`, `GetMoveToPathEx`, and `FinishMoves`. Confirmed in files, not tested.

### Checking a move

`CanStartOperation` for `MOVE_TO` doesn't check the target tile. For a land unit with moves left, it returned `true` for an adjacent tile outside the unit's reachable tiles, and for a deep-water tile 3 tiles away. A `RequestOperation` to the adjacent tile, from `SentientSystemsCore_UI` and from `InGame`, raised no error. The unit stayed on its tile with all its moves. Confirmed on Windows on 2026-10-23.

- With `true` as a fifth argument, `CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, params, true)` returned `true, nil` for the deep-water tile. A move check gives no failure reasons. Confirmed on Windows on 2026-10-23.
- `UnitManager.GetReachableMovement(unit)` returns the plot indexes the unit can reach this turn. The UI draws the movement range from it in `Base/Assets/UI/WorldView/SelectedUnit.lua`, line 53. Confirmed in files. The deep-water tile wasn't in the list, and a move to an adjacent tile from the list worked. Confirmed on Windows on 2026-10-23.
- `Base/Assets/UI/Panels/UnitPanel.lua`, line 609, calls `UnitManager.CanStartOperation(pUnit, UnitOperationTypes.MOVE_TO, nil, false, false)` with the comment "No exclusion test, no results". Confirmed in files.

For other operations and commands, civ6-mcp reads failure reasons from the same form. `local ok, result = UnitManager.CanStartOperation(unit, op, nil, params, true)` returns `result.FailureReasons`, a list of reason strings, when the check fails. `UnitManager.CanStartCommand` and `CityManager.CanStartCommand` return a table of reasons the same way. See [`build_improve_tile`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L1039), [`build_sacrifice_builder_charges`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L1266), and [`build_purchase_item`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/cities.py#L593). Unconfirmed, used by civ6-mcp.

### Checking a route

`UnitManager.GetMoveToPathEx(unit, plotIndex)` returns the route the game's cursor draws, as `WorldInput.lua` reads it. Confirmed in files. The table has `plots`, the plot indexes from the first step to the target, `turns`, the turn each step is reached, and `obstacles`, `exitPortals`, and `entrancePortals`. It is the only check we found that covers a move over more than one turn. Confirmed on Windows on 2026-11-04, with a scout on turn 55:

- For a reachable tile the last plot is the target. A tile 9 away gave 10 plots and 4 turns.
- For a tile with no route, such as an impassable mountain, `plots` is empty.
- For the unit's own tile, `plots` is empty.
- A scout that could embark got a route to an ocean tile, so the route follows what the unit can enter.

A `MOVE_TO` request for a far tile starts at once and uses the moves left. A scout with 3 moves, asked to move to a tile 2 away, moved one tile and stopped with 0 moves. A unit with 0 moves left is refused by our own check, because the request would only queue. Confirmed on Windows on 2026-11-04.

`UnitManager.GetUnit(playerID, unitID)` finds the unit, and a unit ID is only unique within a player: players 0 and 1 each had a unit 196608. Confirmed on Windows on 2026-11-04.

### The war dialog

`MoveUnitToPlot` calls `CombatManager.IsAttackChangeWarState(unit:GetComponentID(), x, y)` when the player can see the tile. A result with entries means the move starts a war, and the first entry is the defending player. Instead of moving, it fires `LuaEvents.Civ6Common_ConfirmWarDialog`, which `DeclareWarPopup.lua` shows. Confirming calls `DiplomacyManager.RequestSession(attacker, defender, "DECLARE_SURPRISE_WAR")`, and nothing repeats the move, so the player moves again. Confirmed in files.

The call returned `{1}` for a tile inside the borders of a player at peace, and an empty list for the tiles around it. A move to a tile with a neutral unit on it was not an attack. Confirmed on Windows on 2026-11-04.

A request sent straight to `RequestOperation`, as the core mod does, fires no event and opens no dialog, so our move checks for the war itself and refuses with a reason. Confirmed in files.

### Unit orders

`UnitPanel.lua` lists the orders. Fortify, sleep, skip turn, alert, and heal are unit operations, and wake, delete, and promote are unit commands. Confirmed in files. The panel checks an operation loosely first, with `CanStartOperation(unit, hash, nil, true)`, which fails only when the unit could never do it. It then checks for real, with `CanStartOperation(unit, hash, nil, false, OperationResultsTypes.NO_TARGETS)`. Commands use `CanStartCommand(unit, command, true)` and then `(unit, command, false)`. Confirmed on Windows on 2026-11-04.

- `UnitOperationTypes` has no `SLEEP`, `SKIP_TURN`, or `HEAL`, so the value is nil and the check returns `false`. The panel reads each hash from `GameInfo.UnitOperations["UNITOPERATION_SLEEP"].Hash`. `UnitOperationTypes.FORTIFY` and `ALERT` exist, and the hash from `GameInfo` matches them.
- The checks gave no failure reasons for these orders. `FAILURE_REASONS` was empty every time.
- `UnitManager.GetActivityType(unit)` returns `ActivityTypes.ACTIVITY_AWAKE`, `SLEEP`, `HOLD` (skip turn), `SENTRY` (fortified or on alert), or `OPERATION`. A unit that isn't awake refused fortify, sleep, and skip until `UnitCommandTypes.WAKE` ran. A unit on alert still accepted alert.
- Fortify made the unit's activity `OPERATION` with 0 fortify turns, and the unit refused wake and sleep until the turn changed. A trader on its route was `OPERATION` too, and refused every order.
- Sleep was allowed for an air unit and refused for land units that can fortify.
- `UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)` returns the promotions in `UnitCommandResults.PROMOTIONS`. `RequestCommand(unit, PROMOTE, { [UnitCommandTypes.PARAM_PROMOTION_TYPE] = index })` took the promotion, with the `GameInfo.UnitPromotions` index. A second request for the same promotion found none to pick.
- `RequestCommand(unit, UnitCommandTypes.DELETE)` removed a knight at once, with no dialog. The UI asks "are you sure" in `OnPromptToDeleteUnit` first, and has no call to answer for it.

### Ending the turn

`UI.RequestAction(ActionTypes.ACTION_ENDTURN)` ends the turn. It's in `Base/Assets/UI/ActionPanel.lua` at line 512. The base UI calls it in five places. Confirmed in files. Sent from `SentientSystemsCore_UI` in single player, it ended the turn, and the next `AGENT_TURN` line came 3 s later. Confirmed on Windows on 2026-10-23.

An end-turn blocker doesn't stop the request. `NotificationManager.GetFirstEndTurnBlocking(Game.GetLocalPlayer())` returned `ENDTURN_BLOCKING_RESEARCH`, the **Choose Research** prompt, before and after the turn ended. `UI.CanEndTurn()` returned `true` with the blocker in place. Confirmed on Windows on 2026-10-23. The base UI checks the blocker itself before it calls `RequestAction`. `DoEndTurn` in `ActionPanel.lua` ends the turn only when the blocker is `NO_ENDTURN_BLOCKING`. For any other blocker, it selects the next unit or opens the blocking notification. `DoEndTurn` starts at line 526. Confirmed in files.

civ6-mcp ends the turn with the same call, in [`build_end_turn`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/notifications.py#L46). It never sends a second request while the first is still in progress, because a repeated request can skip turns. Instead, it waits for the turn number to change. See [`end_turn.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/end_turn.py#L1139). Unconfirmed, used by civ6-mcp.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](game-api.md#method) give a unit ID.

1. **Move a unit.** In a UI state, follow the [move path](#moving-a-unit):
   - get the unit with `UnitManager.GetUnit(playerID, unitID)`,
   - set the target to an adjacent tile whose index is in `UnitManager.GetReachableMovement(unit)`,
   - print the result of `CanStartOperation`, then call `RequestOperation`,
   - read the unit's position again on the next call, because the move may complete asynchronously.
2. **Negative test.** Check a move into deep water for a land unit. Record what `CanStartOperation` returns, with and without `true` as a fifth argument, and whether the tile is in `GetReachableMovement`.
3. **Check a route.** Call `UnitManager.GetMoveToPathEx(unit, plotIndex)` for a tile 9 away, an impassable tile, and the unit's own tile. Compare the last plot with the target, then call `MoveUnit` for each and read the unit's position and moves.
4. **Check the war test.** Call `CombatManager.IsAttackChangeWarState` for tiles in the borders of a player at peace.
5. **End the turn.** Run `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`, and check that the next `AGENT_TURN` line arrives.

## Results

The bridge ran these steps in a single-player game, with one city and one unit.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `CanStartOperation` for a move to deep water at (43, 51), 3 tiles away | `SentientSystemsCore_UI` | `true` | 2026-10-23 |
| The same check with `true` as a fifth argument | `SentientSystemsCore_UI` | `true, nil` | 2026-10-23 |
| `GetReachableMovement` holds (43, 51) | `SentientSystemsCore_UI` | No | 2026-10-23 |
| `CanStartOperation`, then `RequestOperation`, for (42, 50), adjacent and not reachable | `SentientSystemsCore_UI`, then `InGame` | The check passed, and the request raised no error. In `GameCore_Tuner`, `FindID` read the unit at (41, 49) with 2 moves left, 5 times over 5 s after each request | 2026-10-23 |
| `CanStartOperation`, then `RequestOperation`, for (42, 49), adjacent and reachable | `SentientSystemsCore_UI` | The check passed. The unit moved on the map. In `GameCore_Tuner`, `FindID` read it at (42, 49) with 1 move left, 1 s after the request | 2026-10-23 |
| `GetMoveToPathEx` for a reachable tile 9 away, and for a mountain | `SentientSystemsCore_UI` | 10 plots ending at the target with 4 turns, and an empty `plots` | 2026-11-04 |
| `IsAttackChangeWarState` for a tile in the borders of a player at peace, and for the tiles around it | `SentientSystemsCore_UI` | `{1}`, and empty lists | 2026-11-04 |
| `SentientSystems_MoveUnit` for a tile 2 away | `SentientSystemsCore_UI` | `ok`. The scout moved one tile and stopped with 0 moves | 2026-11-04 |
| `SentientSystems_UnitAction` for fortify, skip, wake, promote, and delete on a knight and a caravel | `SentientSystemsCore_UI` | Each took effect. Delete removed the knight | 2026-11-04 |
| `Game.GetCurrentGameTurn()`, `UI.CanEndTurn()`, and `GetFirstEndTurnBlocking` | `SentientSystemsCore_UI` | Turn 1, `true`, and `ENDTURN_BLOCKING_RESEARCH` | 2026-10-23 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` | `SentientSystemsCore_UI` | The turn ended. `AGENT_TURN 0` came 3 s later, and the same three calls returned turn 2, `true`, and `ENDTURN_BLOCKING_RESEARCH` | 2026-10-23 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: moves and the end turn on 2026-10-23, and routes, the war test, and the unit orders on 2026-11-04.
