# Builder jobs and added production

Status: open. The builder jobs, and adding production to a building or a district, are confirmed in a running game. Adding production to a wonder or a project is not.

The game calls the builder job and add production actions wrap, with the Lua state each runs in and where we found each call.

"Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md). The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).

The other unit actions are in the [actions index](README.md).

## Questions

1. Do a builder or an engineer get the wonder, district, and project production commands, with Qin Shi Huang of China, Montezuma of the Aztecs, or a Royal Society built in a Government Plaza? See [Add production](#add-production).

## What we know now

### Builder jobs

`UnitPanel.lua` has no code for the builder jobs. They are plain unit operations with no interface mode, so the panel's loop checks each one loosely and then for real, and `OnUnitActionClicked` requests it with `RequestOperation(unit, hash)` and no parameters.

`UnitOperationTypes` has `BUILD_ROUTE`, `REMOVE_FEATURE`, `HARVEST_RESOURCE`, `REPAIR`, `REPAIR_ROUTE`, and `REMOVE_IMPROVEMENT`, and each matches the hash in `GameInfo.UnitOperations`. Confirmed in files. Confirmed on Windows on 2026-11-05:

- Each request took effect within a second, and the unit had no moves left. Remove feature and harvest used a build charge, and the road, the repairs, and remove improvement used none.
- **Road.** Only a Military Engineer builds roads, and `GameInfo.Route_ValidBuildUnits` lists it for each route. A builder failed the loose check on every tile. The operation has no route parameter.

  The game builds the best route the player has, `ROUTE_RAILROAD` here, and the check returns it as text in `UnitOperationResults.ROUTE_TYPE` with the cost in `ADDITIONAL_DESCRIPTION`.

  An engineer could build on a tile with an older route and on a tile with a pillaged route, and it passed the loose check but failed the real one on a tile that had a railroad.
- **Remove feature.** `GameInfo.Features` has `Removable` and `RemoveTech` for each feature. A check with `OperationResultsTypes.ALL` returns the feature in `FEATURE_TYPE` and its yields in `ADDITIONAL_DESCRIPTION`.

  A jungle with an improvement failed the real check, and passed it after the improvement was removed. A forest on a tile nobody owns failed the loose check, and passed it once `WorldBuilder.CityManager():SetPlotOwner` gave the tile to the player.
- **Harvest.** `GameInfo.Resource_Harvests` has a row, with `PrereqTech`, for each resource that can be harvested. Wheat, rice, and bananas passed. A resource with no row failed the loose check, and so did wheat with a farm and stone with a quarry.
- **Repair.** `REPAIR` repairs a pillaged improvement, and `REPAIR_ROUTE` repairs a pillaged route. Each failed on a tile that had only the other kind. It is the only job that gave a failure reason, "cannot be repaired while a drought is in progress", for two pillaged improvements.
- **Remove improvement.** It removed two different improvements with no dialog.

### Add production

The game has four unit commands that add production to the item a city is building at the cost of a build charge: `UNITCOMMAND_BUILDING_PRODUCTION`, `DISTRICT_PRODUCTION`, `WONDER_PRODUCTION`, and `PROJECT_PRODUCTION`.

`UnitPanel.lua` has no code for them, so its loop checks each one loosely and then for real and requests it with `RequestCommand(unit, hash)` and no parameters.

`UnitCommandTypes` lacks the building one, so the hash comes from `GameInfo.UnitCommands`. Confirmed in files. Confirmed on Windows on 2026-11-05, with a Flood Barrier in the queue of the city Avaricum:

- A military engineer in the city passed the building command, and none of the other three. The request took Flood Barrier from 0 to 8 of 40, which is 20%, and took one build charge and all of the engineer's moves. A second engineer took it from 8 to 16.
- The check then failed for an engineer with no moves left, so the moves matter.
- A builder in the same city failed all four commands. An engineer in a city building a unit failed, and so did an engineer on a tile next to the city.
- **District.** An engineer standing on the tile of the Aqueduct that Lisieux was building passed the district command and none of the others, and the request took the Aqueduct from 0 to 52 of 180 and one charge. A builder on that tile failed, and so did an engineer in the city centre.

  `GetBuildQueue():GetConstructionPlot(hash)` gives the plot index of the district or wonder being built, and -1 for a building in the city and for a project. `Cities.GetPlotPurchaseCity(x, y)` returns the city that owns a tile, including a district's.
- **Wonder and project.** An engineer, a builder, and a Great Engineer got neither command, on the tile of Statue of Zeus, on the tile of Statue of Liberty, and in the city that was building the Manhattan Project. No unit I tried passed them.

  A player reports that a builder gets the wonder command under Qin Shi Huang of China, the district command under Montezuma of the Aztecs, and the project command when the Royal Society was built in a Government Plaza. None of this was tested, because the save has no such leader or building.
- The checks give no reasons and no results.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](../game-api.md#method) give a unit ID.

1. **Builder jobs.** Check and request each job with an engineer or a builder on a tile that allows it and on one that doesn't, print the results of a check with `OperationResultsTypes.ALL`, and read the tile and the unit's charges afterward.

   In `GameCore_Tuner`, `ImprovementBuilder.SetImprovementPillaged(plot, true)` and `RouteBuilder.SetRoutePillaged(plotIndex, true)` set up a pillaged tile.

   To add production, check the four production commands with an engineer and a builder in a city that is building an item, and read the item's progress and the unit's charges afterward.

## Results

The bridge ran these steps in a single-player game.

- **`SentientSystems_UnitAction` for `build_road`, `remove_feature`, `harvest`, `repair`, and `remove_improvement`.** Each took effect once.

  Each gave a reason for one illegal case: a road on a railroad, a remove feature with no feature, a harvest on a farm, a repair of an unpillaged tile, and a repair in a drought.

  Run in `SentientSystemsCore_UI` on 2026-11-05.
- **`SentientSystems_UnitAction` for `add_production` by two military engineers and a builder.** An engineer in a city building a Flood Barrier added 20% of its cost, and one on the tile of an Aqueduct added 52 of 180, each for a charge.

  Each other case gave a reason: a builder, an engineer in a city building something else, an engineer off the tile of a district, an engineer outside a city, and a Great Engineer. Run in `SentientSystemsCore_UI` on 2026-11-05.

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows on 2026-11-05.
