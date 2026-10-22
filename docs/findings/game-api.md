# Game API

Status: open. Partly confirmed from game files. civ6-mcp's code covers more calls, unconfirmed.

This file lists the game calls the bridge needs, with the Lua state (gameplay or UI) and where we found each call. "Confirmed in files" means the game's own Lua uses the call that way. "Tested" means we ran it from the tuner. "Used by civ6-mcp" means [civ6-mcp](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a) calls it that way at commit `dd20190`, read on 2026-10-16. That code plays live games, but we haven't run the call ourselves, so it stays unconfirmed.

## Questions

1. Which call lists a player's cities, and what does each city object expose?
2. Which call lists a player's units, and how do we get one unit by its ID?
3. How do we move a unit, and how do we check a move before we request it?
4. What does a failed check return: a reason, or only `false`?
5. How do we end the turn?
6. Which call returns the active player in single player, and which in hotseat?
7. Can a script write a game property that saves keep, for checkpoint IDs?
8. Can UI Lua dismiss the hotseat pass screen, so agent turns start without a click? Test in phase 2.

## What we know now

### Cities

```lua
for i, pCity in pPlayer:GetCities():Members() do
	-- pCity:GetName(), pCity:GetX(), pCity:GetY(), pCity:GetPopulation()
end
```

- The loop form is confirmed in files: `Base/Assets/UI/WorldView/DistrictPlotIconManager.lua`, line 101.
- civ6-mcp calls `GetID()`, `GetName()`, `GetX()`, `GetY()`, and `GetPopulation()` on each city, in [`build_cities_query`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/cities.py#L16). It passes `GetName()` through `Locale.Lookup` to get the display name. Unconfirmed, used by civ6-mcp.

### Units

- `UnitManager.GetUnit(playerID, unitID)` returns one unit. The game's Lua uses it 41 times. Confirmed in files.
- `pPlayer:GetUnits():Members()` lists units, in the same pattern as cities. civ6-mcp reads `GetID()`, `GetType()`, `GetX()`, `GetY()`, and `GetMovesRemaining()` on each unit, and it skips units whose X position is `-9999`. See [`build_units_query`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L23). Unconfirmed, used by civ6-mcp.
- civ6-mcp gets one unit with `UnitManager.GetUnit` in `InGame`, and with `Players[playerID]:GetUnits():FindID(unitID)` in `GameCore_Tuner`. See [`lua/_helpers.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/_helpers.py#L61). Unconfirmed, used by civ6-mcp.

### Moving a unit

The UI's move path is `MoveUnitToPlot` in `Base/Assets/UI/Civ6Common.lua`, lines 102 to 169. Confirmed in files. Its core:

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

The game's Lua also uses these calls: `CanStartCommand` and `RequestCommand` for unit commands, `GetOperationTargets`, `GetCommandTargets`, and `FinishMoves`. Confirmed in files, not tested.

In the code above, `CanStartOperation` returns a boolean. civ6-mcp passes `true` as the last argument and reads a second return value. For example, `local ok, result = UnitManager.CanStartOperation(unit, op, nil, params, true)` returns `result.FailureReasons`, a list of reason strings, when the check fails. `UnitManager.CanStartCommand` and `CityManager.CanStartCommand` return a table of reasons the same way. See [`build_improve_tile`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L1039), [`build_sacrifice_builder_charges`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L1266), and [`build_purchase_item`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/cities.py#L593). Unconfirmed, used by civ6-mcp. The answer to question 4 decides how the action API builds its failure reasons.

### Ending the turn

`UI.RequestAction(ActionTypes.ACTION_ENDTURN)` ends the turn. It's in `Base/Assets/UI/ActionPanel.lua` at line 512. The base UI calls it in five places. Confirmed in files.

civ6-mcp ends the turn with the same call, in [`build_end_turn`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/notifications.py#L46). It never sends a second request while the first is still in progress, because a repeated request can skip turns. Instead, it waits for the turn number to change. See [`end_turn.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/end_turn.py#L1139). Unconfirmed, used by civ6-mcp.

### Turn number

`Game.GetCurrentGameTurn()` returns the turn number. It's in `Base/Assets/UI/ARXManager.lua` at line 253. Confirmed in files.

### Active player

civ6-mcp reads the player with `Game.GetLocalPlayer()` in every file we read, and its README doesn't mention hotseat. Question 6 stays open for hotseat.

### Turn events

See [lua-contexts.md](lua-contexts.md). The gameplay event is `GameEvents.PlayerTurnStarted`. The UI events are `Events.PlayerTurnActivated` and `Events.LocalPlayerTurnBegin`.

### Game properties (for checkpoint IDs)

- `Game:SetProperty(key, value)` and `Game:GetProperty(key)` appear in `DLC/CivRoyaleScenario/Scripts/CivRoyaleScenario_StartScript.lua`, lines 158 and 173. That file is a gameplay script. Confirmed in files.
- Players have the same methods. `pPlayer:SetProperty` appears in `DLC/BlackDeathScenario/Scripts/BlackDeathScenario.lua`, line 373.
- Unconfirmed: whether the value survives a save and reload, and whether a UI script can call `SetProperty` or only `GetProperty`. Test both in phase 2.

### Mod metadata

- Official `.modinfo` files use a whole-number version, for example `<Mod id="..." version="1">` in `DLC/Australia/Australia.modinfo` and `DLC/Expansion2/Expansion2.modinfo`. Confirmed in files. Most workshop mods do too, but some use `1.2` or `4.2`.
- The game accepts `version="0.1.0"` on `<Mod>`. The mod lists in **Additional Content** and loads. A save made with `version="1"` loads after the change, and a save made with `version="0.1.0"` reloads. Confirmed on Windows on 2026-10-22.
- `Modding.GetModProperty(handle, "Version")` returns `<Properties><Version>`, not the `version` attribute. With the property set to `0.1.0-test`, it returned `0.1.0-test`. Get the handle from `Modding.GetActiveMods()`, whose entries have `Id` and `Handle` but no `Version` field. Confirmed in `InGame` on Windows on 2026-10-22.
- Gameplay states have no `Modding`. `type(Modding)` is `nil` in the core mod's gameplay state. Confirmed on Windows on 2026-10-22.
- The Gathering Storm mod ID is `4873eb62-8ccc-4574-b784-dda455e74e68` (`Expansion2`). Use it for a dependency or in criteria.

## Method

Run each step through the tuner, and record the Lua state you ran it in.

1. **List cities.** Use the [city loop](#cities) for `Game.GetLocalPlayer()`, and print `name, x, y, population` for each city. Run the loop in a gameplay state first, then in a UI state. Compare what each state sees.
2. **List units.** Loop over `Players[id]:GetUnits():Members()` and print `id, type, x, y, moves left`. You need a unit ID for the next step.
3. **Move a unit.** In a UI state, follow the [move path](#moving-a-unit):
   - get the unit with `UnitManager.GetUnit(playerID, unitID)`,
   - set the target to an adjacent passable tile,
   - print the result of `CanStartOperation`, then call `RequestOperation`,
   - read the unit's position again on the next call, because the move may complete asynchronously.
4. **Negative test.** Request a move into deep water for a land unit, and record what `CanStartOperation` returns. This answers question 4.
5. **End the turn.** Run `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`, and check that the next `AGENT_TURN` line arrives.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| | | | |

Date checked: game files on 2026-10-16. Running game on Windows: mod metadata on 2026-10-22.
