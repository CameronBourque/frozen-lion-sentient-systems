# Unit orders

Status: confirmed. The unit orders, the orders on a unit's tile, and upgrades are confirmed in a running game.

The game calls the unit order actions wrap, with the Lua state each runs in and where we found each call. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md). The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md).

The other unit actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Unit orders

`UnitPanel.lua` lists the orders. Fortify, sleep, skip turn, alert, and heal are unit operations, and wake, delete, and promote are unit commands. Confirmed in files. The panel checks an operation loosely first, with `CanStartOperation(unit, hash, nil, true)`, which fails only when the unit could never do it. It then checks for real, with `CanStartOperation(unit, hash, nil, false, OperationResultsTypes.NO_TARGETS)`. Commands use `CanStartCommand(unit, command, true)` and then `(unit, command, false)`. Confirmed on Windows on 2026-11-04.

- `UnitOperationTypes` has no `SLEEP`, `SKIP_TURN`, or `HEAL`, so the value is nil and the check returns `false`. The panel reads each hash from `GameInfo.UnitOperations["UNITOPERATION_SLEEP"].Hash`. `UnitOperationTypes.FORTIFY` and `ALERT` exist, and the hash from `GameInfo` matches them.
- The checks gave no failure reasons for these orders. `FAILURE_REASONS` was empty every time.
- `UnitManager.GetActivityType(unit)` returns `ActivityTypes.ACTIVITY_AWAKE`, `SLEEP`, `HOLD` (skip turn), `SENTRY` (fortified or on alert), or `OPERATION`. A unit that isn't awake refused fortify, sleep, and skip until `UnitCommandTypes.WAKE` ran. A unit on alert still accepted alert.
- Fortify made the unit's activity `OPERATION` with 0 fortify turns, and the unit refused wake and sleep until the turn changed. A trader on its route was `OPERATION` too, and refused every order.
- Sleep was allowed for an air unit and refused for land units that can fortify.
- `UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)` returns the promotions in `UnitCommandResults.PROMOTIONS`. `RequestCommand(unit, PROMOTE, { [UnitCommandTypes.PARAM_PROMOTION_TYPE] = index })` took the promotion, with the `GameInfo.UnitPromotions` index. A second request for the same promotion found none to pick.
- `RequestCommand(unit, UnitCommandTypes.DELETE)` removed a knight at once, with no dialog. The UI asks "are you sure" in `OnPromptToDeleteUnit` first, and has no call to answer for it.

### Orders on the unit's tile

Found city, build improvement, and pillage all act on the tile the unit stands on, as `UnitPanel.lua` does. Confirmed in files. Confirmed on Windows on 2026-11-04:

- The game gives no failure reasons. `FAILURE_REASONS` was empty for a settler next to a city, for an improvement the builder couldn't build, and for a knight on a tile with nothing to pillage, whichever form of the check we used.
- The loose check, `CanStartOperation(unit, hash, nil, true)`, depends on the tile and the unit's moves, not only on the kind of unit. A knight on its own farm and a builder with no moves both failed it. So the kind of unit comes from `GameInfo.Units`: `FoundCity`, `BuildCharges`, and `Combat`.
- Found city is refused within `GlobalParameters.CITY_MIN_RANGE` (3) tiles of a city. A settler 3 tiles from a city was refused, and one 4 tiles away was allowed. It was allowed on a tile nobody owns. A settler moved there founded a city with `RequestOperation(unit, FOUND_CITY)`. The UI asks for confirmation first when a feature would be removed, which has no call to answer.
- `CanStartOperation(unit, BUILD_IMPROVEMENT, nil, { X, Y }, true)` returns, in `UnitOperationResults.IMPROVEMENTS`, every improvement index the unit might build, 18 for a builder. Adding `PARAM_IMPROVEMENT_TYPE` to the parameters checks one for real. A builder on plains hills could build a farm, a mine, an alcazar, and a wind farm. The check accepts the index and the hash. The panel requests with the hash, and the request started a farm.
- A builder in a city center can build nothing, and neither can a sleeping builder, until it wakes. A builder that has started a job has no moves left.
- Pillage was allowed for a knight on an unpillaged improvement in the territory of a player at war, and refused on the player's own farm. After the request, the improvement was pillaged and the check refused a second pillage.
- Units placed with `GameCore_Tuner`'s `UnitManager.InitUnit` take these orders like any other.


### Upgrade

`UnitPanel.lua` checks `UnitCommandTypes.UPGRADE` loosely with `UnitManager.CanStartCommand(unit, command, true)` and then for real with `CanStartCommand(unit, command, false, true)`. It reads the unit the upgrade makes from `UnitCommandResults.UNIT_TYPE`, an index in `GameInfo.Units`, and the cost from `unit:GetUpgradeCost()`. Its `AddUpgradeResourceCost` returns an empty string. `OnUnitActionClicked` requests it with `RequestCommand(unit, command)` and no parameters. Confirmed in files. Confirmed on Windows on 2026-11-05:

- A fortified crossbowman passed the real check and upgraded to a machine gun. Its old ID was gone afterward, and the gold balance fell by the cost, 180.
- The upgrade goes to the last unit of the chain, not the next one. `UNIT_TYPE` was Machine Gun for a crossbowman, which passes through Field Cannon, and Modern Armor for a knight, Mechanized Infantry for a musketman, Destroyer for a caravel, and Rocket Artillery for a bombard. The cost is that of the whole chain, and `GameInfo.UnitUpgrades` gives each step.
- The real check returns `UnitCommandResults.FAILURE_REASONS`, a list of text, with a reason for each shortfall at once. The reasons were "Not enough [ICON_Gold] Gold in treasury.", "Insufficient Resources. 1 [ICON_RESOURCE_OIL] Oil required to upgrade this type of unit.", and "Must be in friendly territory.", which a caravel and a knight outside the borders got. The gold reason gives no amount.
- The loose check fails, with no results table, for a unit with no moves left and for a kind of unit with no upgrade. It also failed for a crossbowman and a knight after `SetTech(index, false)` in `GameCore_Tuner` took away Ballistics, the tech of the next unit in their chain, though the last unit was still available. One missing step blocks the whole upgrade. A unit with 0.25 moves passed.
- `GetUpgradeCost()` returned the cost for a unit with no moves and for one with a missing step, and 0 for a builder, a settler, and the great people, so the cost alone doesn't say whether an upgrade exists.
- `GameInfo.UnitUpgrades` has a row for each `Unit` and `UpgradeUnit`, and the row of each unit in `GameInfo.Units` has `PrereqTech` and `PrereqCivic`. In the UI state, `HasTech` still returned true after `SetTech(index, false)`, so the reason that names a missing step wasn't checked in the running game.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](../game-api.md#method) give a unit ID.

1. **Unit orders.** For each order, call the loose check and then the real check, then request it. Read `UnitManager.GetActivityType(unit)` and the unit's moves before and after.
2. **Orders on the unit's tile.** Call the check and the request for found city, build improvement, and pillage with the unit on a tile that allows the order and on one that doesn't, and print `FAILURE_REASONS`.
3. **Upgrade.** Call the loose check and the real check with results for units that can upgrade and units that can't, then request it and read the gold and the unit afterward. In `GameCore_Tuner`, `ChangeGoldBalance`, `ChangeResourceAmount` on `GetResources()`, and `SetTech` change the gold, the strategic resources, and the techs.

## Results

The bridge ran these steps in a single-player game.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_UnitAction` for fortify, skip, wake, promote, and delete on a knight and a caravel | `SentientSystemsCore_UI` | Each took effect. Delete removed the knight | 2026-11-04 |
| `SentientSystems_UnitAction` for `improve`, `found_city`, and `pillage` | `SentientSystemsCore_UI` | A farm was started, a city was founded, and an enemy improvement was pillaged. The reasons came from the checks in the Lua | 2026-11-04 |
| `SentientSystems_UnitAction` for `upgrade` on a crossbowman, a caravel, a builder, a unit with no moves, and a unit short of gold or a resource | `SentientSystemsCore_UI` | The crossbowman became a machine gun and cost 180 gold. Each other case gave a reason: the territory, no upgrade, no moves, gold, and the resource | 2026-11-05 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows on 2026-11-04 for the unit orders and the orders on a unit's tile, and on 2026-11-05 for upgrades.
