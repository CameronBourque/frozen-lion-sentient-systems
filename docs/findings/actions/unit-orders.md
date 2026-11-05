# Unit orders and attacks

Status: open. The unit orders, the orders on a unit's tile, the builder jobs, adding production, upgrades, formations, and air moves are confirmed in a running game, and attacks are confirmed except the priority target.

The game calls the unit order and attack actions wrap, with the Lua state each runs in and where we found each call. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md). The core mod's result format is in [in-game-lua.md](../../design/core/in-game-lua.md). The move path and the war dialog are in [actions/move-unit.md](move-unit.md).

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

### Builder jobs

`UnitPanel.lua` has no code for the builder jobs. They are plain unit operations with no interface mode, so the panel's loop checks each one loosely and then for real, and `OnUnitActionClicked` requests it with `RequestOperation(unit, hash)` and no parameters. `UnitOperationTypes` has `BUILD_ROUTE`, `REMOVE_FEATURE`, `HARVEST_RESOURCE`, `REPAIR`, `REPAIR_ROUTE`, and `REMOVE_IMPROVEMENT`, and each matches the hash in `GameInfo.UnitOperations`. Confirmed in files. Confirmed on Windows on 2026-11-05:

- Each request took effect within a second, and the unit had no moves left. Remove feature and harvest used a build charge, and the road, the repairs, and remove improvement used none.
- **Road.** Only a Military Engineer builds roads, and `GameInfo.Route_ValidBuildUnits` lists it for each route. A builder failed the loose check on every tile. The operation has no route parameter. The game builds the best route the player has, `ROUTE_RAILROAD` here, and the check returns it as text in `UnitOperationResults.ROUTE_TYPE` with the cost in `ADDITIONAL_DESCRIPTION`. An engineer could build on a tile with an older route and on a tile with a pillaged route, and it passed the loose check but failed the real one on a tile that had a railroad.
- **Remove feature.** `GameInfo.Features` has `Removable` and `RemoveTech` for each feature. A check with `OperationResultsTypes.ALL` returns the feature in `FEATURE_TYPE` and its yields in `ADDITIONAL_DESCRIPTION`. A jungle with an improvement failed the real check, and passed it after the improvement was removed. A forest on a tile nobody owns failed the loose check, and passed it once `WorldBuilder.CityManager():SetPlotOwner` gave the tile to the player.
- **Harvest.** `GameInfo.Resource_Harvests` has a row, with `PrereqTech`, for each resource that can be harvested. Wheat, rice, and bananas passed. A resource with no row failed the loose check, and so did wheat with a farm and stone with a quarry.
- **Repair.** `REPAIR` repairs a pillaged improvement, and `REPAIR_ROUTE` repairs a pillaged route. Each failed on a tile that had only the other kind. It is the only job that gave a failure reason, "cannot be repaired while a drought is in progress", for two pillaged improvements.
- **Remove improvement.** It removed two different improvements with no dialog.

### Add production

The game has four unit commands that add production to the item a city is building at the cost of a build charge: `UNITCOMMAND_BUILDING_PRODUCTION`, `DISTRICT_PRODUCTION`, `WONDER_PRODUCTION`, and `PROJECT_PRODUCTION`. `UnitPanel.lua` has no code for them, so its loop checks each one loosely and then for real and requests it with `RequestCommand(unit, hash)` and no parameters. `UnitCommandTypes` lacks the building one, so the hash comes from `GameInfo.UnitCommands`. Confirmed in files. Confirmed on Windows on 2026-11-05, with a Flood Barrier in the queue of the city Avaricum:

- A military engineer in the city passed the building command, and none of the other three. The request took Flood Barrier from 0 to 8 of 40, which is 20%, and took one build charge and all of the engineer's moves. A second engineer took it from 8 to 16.
- The check then failed for an engineer with no moves left, so the moves matter.
- A builder in the same city failed all four commands. An engineer in a city building a unit failed, and so did an engineer on a tile next to the city.
- The checks give no reasons and no results. The district, wonder, and project commands weren't tried, because no city in the save was building such an item.

### Upgrade

`UnitPanel.lua` checks `UnitCommandTypes.UPGRADE` loosely with `UnitManager.CanStartCommand(unit, command, true)` and then for real with `CanStartCommand(unit, command, false, true)`. It reads the unit the upgrade makes from `UnitCommandResults.UNIT_TYPE`, an index in `GameInfo.Units`, and the cost from `unit:GetUpgradeCost()`. Its `AddUpgradeResourceCost` returns an empty string. `OnUnitActionClicked` requests it with `RequestCommand(unit, command)` and no parameters. Confirmed in files. Confirmed on Windows on 2026-11-05:

- A fortified crossbowman passed the real check and upgraded to a machine gun. Its old ID was gone afterward, and the gold balance fell by the cost, 180.
- The upgrade goes to the last unit of the chain, not the next one. `UNIT_TYPE` was Machine Gun for a crossbowman, which passes through Field Cannon, and Modern Armor for a knight, Mechanized Infantry for a musketman, Destroyer for a caravel, and Rocket Artillery for a bombard. The cost is that of the whole chain, and `GameInfo.UnitUpgrades` gives each step.
- The real check returns `UnitCommandResults.FAILURE_REASONS`, a list of text, with a reason for each shortfall at once. The reasons were "Not enough [ICON_Gold] Gold in treasury.", "Insufficient Resources. 1 [ICON_RESOURCE_OIL] Oil required to upgrade this type of unit.", and "Must be in friendly territory.", which a caravel and a knight outside the borders got. The gold reason gives no amount.
- The loose check fails, with no results table, for a unit with no moves left and for a kind of unit with no upgrade. It also failed for a crossbowman and a knight after `SetTech(index, false)` in `GameCore_Tuner` took away Ballistics, the tech of the next unit in their chain, though the last unit was still available. One missing step blocks the whole upgrade. A unit with 0.25 moves passed.
- `GetUpgradeCost()` returned the cost for a unit with no moves and for one with a missing step, and 0 for a builder, a settler, and the great people, so the cost alone doesn't say whether an upgrade exists.
- `GameInfo.UnitUpgrades` has a row for each `Unit` and `UpgradeUnit`, and the row of each unit in `GameInfo.Units` has `PrereqTech` and `PrereqCivic`. In the UI state, `HasTech` still returned true after `SetTech(index, false)`, so the reason that names a missing step wasn't checked in the running game.

### Formations

`GameInfo.UnitCommands` has `ENTER_FORMATION`, `EXIT_FORMATION`, `FORM_CORPS`, and `FORM_ARMY`. The corps needs the civic Nationalism and the army needs Mobilization, as `PrereqCivic` says in `UnitCommands.xml`. For `ENTER_FORMATION`, `UnitPanel.lua` calls `CanStartCommand(unit, hash, nil, true)`, reads the units in `UnitCommandResults.UNITS`, each with a player and an ID, and adds one button for each. `OnUnitActionClicked_EnterFormation` requests the command with `PARAM_UNIT_PLAYER` and `PARAM_UNIT_ID` of the chosen unit. A corps and an army use an interface mode. `WorldInput.lua` takes each unit on the clicked tile, checks `FORM_CORPS` or `FORM_ARMY` with those two parameters, and requests it. `UnitManager.GetCommandTargets(unit, command)` returns the same list in `UNITS`. Exit has no parameters, and the panel's loop requests it with `RequestCommand(unit, command)`. Confirmed in files. Confirmed on Windows on 2026-11-05:

- **Corps.** The other unit has to be of the same kind and on an adjacent tile. Three knights on one tile didn't list each other, and a knight next to them listed all three. A knight formed a corps with the knight next to it. The other knight was gone, `GetMilitaryFormation()` was 1, and the unit had no moves left. A unit with no moves failed the loose check and had no targets. A partner with no moves was still listed. Two builders next to each other failed, and their `FormationClass` is `FORMATION_CLASS_CIVILIAN`.
- **Army.** The player had Nationalism and lacked Mobilization, and the check failed. After `SetCivic(index, true)` in `GameCore_Tuner`, a corps listed an adjacent knight that was not in a formation, and that knight listed the corps. They formed an army, with `GetMilitaryFormation()` of 2. The other knight was gone.
- **Enter and exit.** A knight and a crossbowman on a tile with a builder listed the builder, and the builder listed them. Two knights on a tile didn't list each other. After a knight entered, both units had `GetFormationUnitCount()` of 2 on the same tile, and exit was allowed for both. Exit took them back to 1. The plain check of `ENTER_FORMATION` returned false where the check with results returned true. A medic, which is a support unit, listed the knights and the crossbowman but not the builder, and the builder did not list the medic. A frigate on a coast tile listed an embarked builder and an embarked knight, and each of them listed the frigate, but two frigates didn't list each other. A medic with a knight and a frigate with the builder entered through the action, and each pair's count rose to 2.
- A corps and an army failed the check for exit with moves restored, and `RestoreMovement` in `GameCore_Tuner` gave the moves back.
- The checks give only the `UNITS` list and no reasons. A request changed the units after the call returned, not inside it.

### Air moves

`WorldInput.lua` makes four air calls, each in an interface mode that the player clicks a tile in. Rebase and deploy are unit operations: `AirUnitReBase` and `AirUnitDeploy` check `CanStartOperation(unit, REBASE or DEPLOY, nil, { PARAM_X, PARAM_Y })` and request it with the same parameters. Airlift is the unit command `AIRLIFT`, and `UnitAirlift` uses `UnitCommandTypes.PARAM_X` and `PARAM_Y`. Paradrop is the command `PARADROP` of the Rise and Fall expansion, and `UnitParadrop` in `WorldInput_Expansion1.lua` does the same. Each mode lists its tiles with `UnitManager.GetOperationTargets` or `GetCommandTargets`, as `PLOTS` plot indexes. Confirmed in files. Confirmed on Windows on 2026-11-05:

- **Rebase.** A jet fighter at a city listed 13 tiles up to 20 away, such as cities, an aerodrome, and an airstrip. It moved to a city 7 tiles away and had no moves left, and the check then failed. A plain land tile failed.
- **Deploy.** The same fighter listed 218 tiles up to 10 away, including plain land. The request kept the unit in its city and set its activity to `ACTIVITY_INTERCEPT`. It passed with no moves left.
- **Airlift.** An infantry unit in a city with an airport listed 12 tiles around the aerodrome of the other city with an airport, and landed on one of them with no moves left. Infantry on the aerodrome tile and on a tile next to it listed targets too, and a city with no airport listed none. A frigate on the water next to an aerodrome with an airport listed none, where infantry on the aerodrome listed 9. In `GameCore_Tuner`, `WorldBuilder.CityManager():CreateDistrict` and `CreateBuilding` built the aerodrome, the hangar, and the airport.
- **Paradrop.** Spec ops, the only unit with `CLASS_PARADROP` in `GameInfo.TypeTags`, listed about 130 tiles up to 7 away from a city, and about 200 from a tile with an airstrip. It landed 3 tiles away with no moves left. Infantry failed, and so did spec ops on a bare tile.
- Airlift and paradrop are for land units, and air units rebase instead. A unit with no moves failed rebase, airlift, and paradrop. `CanStartCommand(unit, command, nil, parameters)` ignored the tile, and `CanStartCommand(unit, command, parameters)` checked it.
- The checks give no reasons and no results besides the tiles.

### Attacks

`WorldInput.lua` and `Civ6Common.lua` make three attack calls, and `RequestMoveOperation` picks one. Confirmed in files. Confirmed on Windows on 2026-11-04:

- **Ranged and bombard.** `UnitManager.CanStartOperation(unit, RANGE_ATTACK, nil, { X, Y })` and `RequestOperation` with the same parameters. The UI picks it when the unit's ranged or bombard strength is above its melee strength. A crossbowman hit a unit 1 tile away, and another hit a heavy chariot 2 tiles away.
- **Air.** The same with `AIR_ATTACK`. A jet bomber hit a unit within its range of 15.
- **Melee.** `MOVE_TO` with `UnitOperationMoveModifiers.ATTACK` plus `MOVE_IGNORE_UNEXPLORED_DESTINATION`, as the move path does. A knight damaged a trebuchet on the next tile. A knight attacking a tile with only an enemy builder captured it: the builder became the player's, and the knight stood on the tile.
- **Targets.** `UnitManager.GetOperationTargets(unit, op)` returns `UnitOperationResults.PLOTS` and `MODIFIERS`. A tile with `MODIFIER_IS_TARGET` holds something to hit, and the others are in range only. A tile behind a forest was missing from a crossbowman's list, so the list also reflects line of sight.
- The checks give no reasons. A unit with no attacks left failed `CanStartOperation` for every tile with an empty `FAILURE_REASONS`, and `GetAttacksRemaining()` explains it.
- `Units.GetUnitsInPlot(plot)` lists the units on a tile, and `CityManager.GetCityAt(x, y)` gives its city.
- **War.** `CombatManager.IsAttackChangeWarState` gives the same answer for an attack as for a move, and `UnitAirAttack` and the coastal raid call it the same way. A tile inside the borders of a player at peace returned the player, with or without a unit on it. Attacking a visible tile there is refused by the core mod. The dialog is the same as for a move, in [the war dialog](move-unit.md#the-war-dialog).
- **Priority target.** `UNITCOMMAND_PRIORITY_TARGET` is a unit command of the Rise and Fall expansion. It hits the support or civilian unit that a military unit escorts, instead of the military unit. `WorldInput_Expansion1.lua` lists its tiles with `UnitManager.GetCommandTargets(unit, command)`, highlights those marked with `CityCommandResults.MODIFIER_IS_TARGET`, and checks and requests it with `UnitCommandTypes.PARAM_X` and `PARAM_Y`. Confirmed in files. Confirmed on Windows on 2026-11-05: the check passed for spec ops, a bomber, a jet bomber, and a fighter that had moves, and failed for units with none. It listed every tile in range, 464 for the jet bomber, and marked none. A knight and a builder on one tile weren't marked, and the command failed for the tile. An enemy heavy chariot escorting a settler, in range of the jet bomber and in sight, wasn't marked either, though the air attack didn't mark it. `RequestCommand` did nothing for an enemy unit, so a tile that is marked, and a request that works, haven't been seen.
- **City attack.** `CityManager.GetCommandTargets(city, CityCommandTypes.RANGE_ATTACK, {})` returns the tiles in `CityCommandResults.PLOTS` with `MODIFIERS`, and `CityManager.CanStartCommand` and `RequestCommand` take `{ X, Y }`. `CityRangeAttack` shows no war dialog. A city hit an enemy unit on the next tile, and left it with 22 damage.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](../game-api.md#method) give a unit ID.

1. **Unit orders.** For each order, call the loose check and then the real check, then request it. Read `UnitManager.GetActivityType(unit)` and the unit's moves before and after.
2. **Orders on the unit's tile.** Call the check and the request for found city, build improvement, and pillage with the unit on a tile that allows the order and on one that doesn't, and print `FAILURE_REASONS`.
3. **Builder jobs.** Check and request each job with an engineer or a builder on a tile that allows it and on one that doesn't, print the results of a check with `OperationResultsTypes.ALL`, and read the tile and the unit's charges afterward. In `GameCore_Tuner`, `ImprovementBuilder.SetImprovementPillaged(plot, true)` and `RouteBuilder.SetRoutePillaged(plotIndex, true)` set up a pillaged tile. To add production, check the four production commands with an engineer and a builder in a city that is building an item, and read the item's progress and the unit's charges afterward.
4. **Upgrade.** Call the loose check and the real check with results for units that can upgrade and units that can't, then request it and read the gold and the unit afterward. In `GameCore_Tuner`, `ChangeGoldBalance`, `ChangeResourceAmount` on `GetResources()`, and `SetTech` change the gold, the strategic resources, and the techs.
5. **Formations.** List `GetCommandTargets` for each command, check with the other unit's player and ID, request it, and read `GetMilitaryFormation()`, `GetFormationUnitCount()`, and the moves afterward. In `GameCore_Tuner`, `InitUnit` spawns the units, `RestoreMovement` and `ChangeMovesRemaining` set the moves, and `SetCivic` gives a civic.
6. **Air moves.** List the targets, check with a tile, and request each order with air units, a spec ops unit, and an infantry unit in cities with and without an airport, and read the unit's tile, moves, and activity afterward.
7. **Attacks.** Call `GetOperationTargets`, the check, and the request for a ranged, an air, and a melee unit, and for a city. Read the target's damage afterward.

## Results

The bridge ran these steps in a single-player game.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_UnitAction` for fortify, skip, wake, promote, and delete on a knight and a caravel | `SentientSystemsCore_UI` | Each took effect. Delete removed the knight | 2026-11-04 |
| `SentientSystems_UnitAction` for `improve`, `found_city`, and `pillage` | `SentientSystemsCore_UI` | A farm was started, a city was founded, and an enemy improvement was pillaged. The reasons came from the checks in the Lua | 2026-11-04 |
| `SentientSystems_UnitAction` for `build_road`, `remove_feature`, `harvest`, `repair`, and `remove_improvement` | `SentientSystemsCore_UI` | Each took effect once, and each gave a reason for one illegal case: a road on a railroad, a remove feature with no feature, a harvest on a farm, a repair of an unpillaged tile, and a repair in a drought | 2026-11-05 |
| `SentientSystems_UnitAction` for `add_production` by two military engineers and a builder | `SentientSystemsCore_UI` | An engineer in a city building a Flood Barrier added 20% of its cost and used a charge. Each other case gave a reason: a builder, an engineer in a city building something else, an engineer outside a city, and a unit that isn't a builder | 2026-11-05 |
| `SentientSystems_UnitAction` for `upgrade` on a crossbowman, a caravel, a builder, a unit with no moves, and a unit short of gold or a resource | `SentientSystemsCore_UI` | The crossbowman became a machine gun and cost 180 gold. Each other case gave a reason: the territory, no upgrade, no moves, gold, and the resource | 2026-11-05 |
| `SentientSystems_UnitAction` for `form_corps`, `form_army`, `enter_formation`, and `exit_formation` | `SentientSystemsCore_UI` | A musketman formed a corps and then an army, and a knight entered and left a builder's tile formation. Each other case gave a reason: no unit named, a unit that can't join, a builder, no moves, a corps that can't exit, and a missing civic | 2026-11-05 |
| `SentientSystems_UnitAction` for `rebase`, `deploy`, `airlift`, and `paradrop` | `SentientSystemsCore_UI` | A fighter rebased and deployed, an infantry unit airlifted, and a spec ops unit paradropped. Each other case gave a reason: a tile out of range, a unit of the wrong kind, no moves, no airport, and no city or airstrip | 2026-11-05 |
| `SentientSystems_UnitAction` `attack` by a crossbowman, a knight, and a jet bomber, and `SentientSystems_CityAttack` | `SentientSystemsCore_UI` | Each hit its target. The knight captured a lone builder. A tile in the borders of a player at peace returned the war reason | 2026-11-04 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: the unit orders, the orders on a unit's tile, and attacks on 2026-11-04, and the builder jobs, adding production, upgrades, formations, and air moves on 2026-11-05.
