# Unit orders and attacks

Status: open. The unit orders, the orders on a unit's tile, and attacks are confirmed in a running game.

The game calls the unit order and attack actions wrap, with the Lua state each runs in and where we found each call. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](game-api.md). The core mod's result format is in [in-game-lua.md](../design/core/in-game-lua.md). The move path and the war dialog are in [actions-move-unit.md](actions-move-unit.md).

## Questions

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

### Attacks

`WorldInput.lua` and `Civ6Common.lua` make three attack calls, and `RequestMoveOperation` picks one. Confirmed in files. Confirmed on Windows on 2026-11-04:

- **Ranged and bombard.** `UnitManager.CanStartOperation(unit, RANGE_ATTACK, nil, { X, Y })` and `RequestOperation` with the same parameters. The UI picks it when the unit's ranged or bombard strength is above its melee strength. A crossbowman hit a unit 1 tile away, and another hit a heavy chariot 2 tiles away.
- **Air.** The same with `AIR_ATTACK`. A jet bomber hit a unit within its range of 15.
- **Melee.** `MOVE_TO` with `UnitOperationMoveModifiers.ATTACK` plus `MOVE_IGNORE_UNEXPLORED_DESTINATION`, as the move path does. A knight damaged a trebuchet on the next tile. A knight attacking a tile with only an enemy builder captured it: the builder became the player's, and the knight stood on the tile.
- **Targets.** `UnitManager.GetOperationTargets(unit, op)` returns `UnitOperationResults.PLOTS` and `MODIFIERS`. A tile with `MODIFIER_IS_TARGET` holds something to hit, and the others are in range only. A tile behind a forest was missing from a crossbowman's list, so the list also reflects line of sight.
- The checks give no reasons. A unit with no attacks left failed `CanStartOperation` for every tile with an empty `FAILURE_REASONS`, and `GetAttacksRemaining()` explains it.
- `Units.GetUnitsInPlot(plot)` lists the units on a tile, and `CityManager.GetCityAt(x, y)` gives its city.
- **War.** `CombatManager.IsAttackChangeWarState` gives the same answer for an attack as for a move, and `UnitAirAttack` and the coastal raid call it the same way. A tile inside the borders of a player at peace returned the player, with or without a unit on it. Attacking a visible tile there is refused by the core mod. The dialog is the same as for a move, in [the war dialog](actions-move-unit.md#the-war-dialog).
- **City attack.** `CityManager.GetCommandTargets(city, CityCommandTypes.RANGE_ATTACK, {})` returns the tiles in `CityCommandResults.PLOTS` with `MODIFIERS`, and `CityManager.CanStartCommand` and `RequestCommand` take `{ X, Y }`. `CityRangeAttack` shows no war dialog. A city hit an enemy unit on the next tile, and left it with 22 damage.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](game-api.md#method) give a unit ID.

1. **Unit orders.** For each order, call the loose check and then the real check, then request it. Read `UnitManager.GetActivityType(unit)` and the unit's moves before and after.
2. **Orders on the unit's tile.** Call the check and the request for found city, build improvement, and pillage with the unit on a tile that allows the order and on one that doesn't, and print `FAILURE_REASONS`.
3. **Attacks.** Call `GetOperationTargets`, the check, and the request for a ranged, an air, and a melee unit, and for a city. Read the target's damage afterward.

## Results

The bridge ran these steps in a single-player game.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_UnitAction` for fortify, skip, wake, promote, and delete on a knight and a caravel | `SentientSystemsCore_UI` | Each took effect. Delete removed the knight | 2026-11-04 |
| `SentientSystems_UnitAction` for `improve`, `found_city`, and `pillage` | `SentientSystemsCore_UI` | A farm was started, a city was founded, and an enemy improvement was pillaged. The reasons came from the checks in the Lua | 2026-11-04 |
| `SentientSystems_UnitAction` `attack` by a crossbowman, a knight, and a jet bomber, and `SentientSystems_CityAttack` | `SentientSystemsCore_UI` | Each hit its target. The knight captured a lone builder. A tile in the borders of a player at peace returned the war reason | 2026-11-04 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: the unit orders, the orders on a unit's tile, and attacks on 2026-11-04.
