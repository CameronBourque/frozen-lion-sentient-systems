# Game choices

Status: open. `SentientSystems_GetChoices` with the units, buildings, districts, and wonders each city can produce, and their tiles, is confirmed in a running game. Corps and armies are confirmed in files only.

The calls the choices use to list the legal options for each of one player's discrete choices, as the game's own screens list them. The end-turn blockers that the choices resolve are in [game-state.md](game-state.md#end-turn-blockers). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does a unit's corps and army option read as the production panel shows it, once the Nationalism and Mobilization civics allow one?

## What we know now

### Units

`GetData` in `Base/Assets/UI/Panels/ProductionPanel.lua`, lines 2113 to 2202, builds the panel's unit list from `GameInfo.Units()`. For each row, with `params = { UnitType = row.Hash, MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION }` and the city's `GetBuildQueue()`:

- **Listed.** The panel lists a unit when `row.MustPurchase` is false and `buildQueue:CanProduce(params, true)` returns `true`. It hides every other unit, such as one whose tech the player doesn't have. Confirmed in files and on Windows on 2026-10-26.
- **Greyed out.** A listed unit is greyed out when `buildQueue:CanProduce(params, false, true)` returns `false`. Its second value is a results table, and `results[CityCommandResults.FAILURE_REASONS]` lists the reasons. `ComposeFailureReasonStrings`, lines 1574 to 1588, passes each through `Locale.Lookup`. Each reason arrives as text in the game's language, not as a text key, so `Locale.Lookup` returns it unchanged. A reason keeps the game's icon markup, such as `[ICON_Citizen]`. Confirmed in files and on Windows on 2026-10-26.
- **Cost, progress, and turns.** `buildQueue:GetUnitCost(row.Index)`, `GetUnitProgress(row.Index)`, and `GetTurnsLeft(row.Hash)`. The panel shows progress only when it is above 0, in `ComposeProductionCostString`, lines 1589 to 1600. Turns change with the city's production, and Rome's settler went from 6 turns to 9 when the city dropped from 3 population to 1. Confirmed in files and on Windows on 2026-10-26.
- **Corps and armies.** When `results[CityOperationResults.CAN_TRAIN_CORPS]` is set, the panel also offers a corps. It checks `CanProduce` again with `MilitaryFormationTypes.CORPS_MILITARY_FORMATION`, and reads `GetUnitCorpsCost(row.Index)` and `GetTurnsLeft(row.Hash, MilitaryFormationTypes.CORPS_MILITARY_FORMATION)`. `CAN_TRAIN_ARMY` works the same way with `ARMY_MILITARY_FORMATION` and `GetUnitArmyCost`. Confirmed in files.
### Buildings

`GetData` in `ProductionPanel.lua`, lines 2020 to 2081, builds the panel's building list from `GameInfo.Buildings()`, after the districts. For each row, with the city's `GetBuildQueue()` and `GetBuildings()`:

- **Listed.** The panel lists a building when `buildQueue:CanProduce(row.Hash, true)` returns `true`, the building isn't in production, and `row.MustPurchase` is false or `cityBuildings:IsPillaged(row.Hash)` is `true`. It leaves out a building whose `row.PrereqDistrict` is the type in production, as when the district is being repaired. `CanProduce` takes the building's hash, where a unit takes a table. Confirmed in files and on Windows on 2026-10-26.
- **Greyed out.** A listed building is greyed out when `buildQueue:CanProduce(row.Hash, false, true)` returns `false`, with the reasons in `results[CityCommandResults.FAILURE_REASONS]`, as for units. Confirmed in files.
- **Cost, progress, turns, and repair.** `buildQueue:GetBuildingCost(row.Index)`, `GetBuildingProgress(row.Index)`, and `GetTurnsLeft(row.Hash)`. A building for which `IsPillaged(row.Hash)` is `true` is listed as a repair. Confirmed in files and on Windows on 2026-10-26.
- **Districts.** `PopulateDistrictsWithNestedBuildings`, lines 1029 to 1035, draws each building under the entry for its `row.PrereqDistrict`. The granary and the walls have `DISTRICT_CITY_CENTER`. Confirmed in files and on Windows on 2026-10-26.
- **Wonders.** A wonder's row has `IsWonder` set to `true`, and no `PrereqDistrict`. The panel lists it with the same checks as a building, and greys it out as [placement tiles](#placement-tiles) describes. Confirmed in files and on Windows on 2026-10-26.
- **Turns that never end.** The panel shows `999+` and `TXT_HUD_CITY_WILL_NOT_COMPLETE` when `GetTurnsLeft` returns -1, in `PopulateDistrictsWithNestedBuildings`, lines 961 to 964. Confirmed in files.

### Districts

`GetData` in `ProductionPanel.lua`, lines 1898 to 2018, builds the panel's district list from `GameInfo.Districts()`, before the buildings. For each row, with the city's `GetBuildQueue()` and `GetDistricts()`:

- **Listed.** The panel lists a district when `buildQueue:CanProduce(row.Hash, true)` returns `true` or `cityDistricts:HasDistrict(row.Index)` is `true`. It leaves out a row whose `InternalOnly` is `true`, and a one-per-city district that is in production. Confirmed in files and on Windows on 2026-10-26.
- **Built.** For a one-per-city district that the city has, that is complete, not pillaged or contaminated, and has no progress, the panel shows a checkmark in place of turns, in `PopulateDistrictsWithNestedBuildings`, line 953. Rome's panel showed **City Center** with a checkmark. Confirmed in files and on Windows on 2026-10-26.
- **Greyed out.** The panel starts from `buildQueue:CanProduce(row.Hash, false, true)`, then checks the tiles from `GetCityRelatedPlotIndexesDistrictsAlternative`. With no tile, it greys the district out unless the city has placed it already, and greys a placed one out when a reason is the text of `LOC_DISTRICT_REPAIR_LOCATION_FLOODED`. With a tile, it doesn't grey the district out when every reason equals `LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION`. That check compares the reasons with the text key, not its text. Confirmed in files.
- **Cost, progress, turns, and repair.** `buildQueue:GetDistrictCost(row.Index)`, `GetDistrictProgress(row.Index)`, and `GetTurnsLeft(row.DistrictType)`, which takes the type name. A district for which `cityDistricts:IsPillaged(row.Index)` is `true` is a repair. Confirmed in files and on Windows on 2026-10-26.

### Placement tiles

`Base/Assets/UI/AdjacencyBonusSupport.lua` finds the tiles where a district or a wonder can go. The expansions don't replace it. Confirmed in files.

- **Tiles the city owns.** `CityManager.GetOperationTargets(city, CityOperationTypes.BUILD, params)`, with `params[CityOperationTypes.PARAM_DISTRICT_TYPE]` set to a district's hash, or `params[CityOperationTypes.PARAM_BUILDING_TYPE]` to a wonder's, returns plot indexes in `results[CityOperationResults.PLOTS]`. Confirmed in files and on Windows on 2026-10-26.
- **Tiles to buy.** `CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, params)`, with `params[CityCommandTypes.PARAM_PLOT_PURCHASE]` set to `UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE)`, returns the plot indexes the city could buy in `results[CityCommandResults.PLOTS]`. `plot:CanHaveDistrict(districtIndex, owner, cityID)` and `plot:CanHaveWonder(buildingIndex, owner, cityID)` check each one. Both work in `SentientSystemsCore_UI`. Rome had 17 tiles to buy. Confirmed in files and on Windows on 2026-10-26.
- **Tiles to buy that the panel counts.** For a district, `IsShownIfPlotPurchaseable`, lines 155 to 169, keeps a tile to buy only when the district gets an adjacency bonus on it, or when the district has no adjacency bonuses. For a wonder, it keeps every tile that `CanHaveWonder` allows. Confirmed in files.
- **Adjacency.** `plot:GetAdjacencyYield(playerID, cityID, districtIndex, yieldIndex)` returns a district's bonus on a tile for one yield. `GetAdjacentYieldBonusString`, lines 177 to 247, reads it for each yield. Confirmed in files and on Windows on 2026-10-26.
- **Wonders with no tile the city owns.** When `CanProduce` refuses a wonder with `results[CityOperationResults.NO_SUITABLE_LOCATION]` set to `true`, the panel doesn't grey it out if it has a tile to buy, in `GetData`, lines 2041 to 2047. The Pyramids, the Great Bath, and Stonehenge each had no tile in Rome's territory and one tile to buy, and Rome's panel showed the Pyramids and the Great Bath in the same style as the buildings. Confirmed in files and on Windows on 2026-10-26.

### Other modes

- **Heroes and Legends.** The game mode replaces the panel with `DLC/Babylon/UI/Replacements/ProductionPanel_Babylon_Heroes.lua`. The choices don't follow that file. Confirmed in files.

## Method

1. In `SentientSystemsCore_UI`, loop over `GameInfo.Units()` and `GameInfo.Buildings()` for each city with the checks above, and compare the lists with the production panel.
2. To unlock buildings and districts in an early game, in `GameCore_Tuner`, send `Players[0]:GetTechs():SetTech(GameInfo.Technologies["TECH_POTTERY"].Index, true)`, and the same for `TECH_MASONRY`, `TECH_WRITING`, and `TECH_ASTROLOGY`. Reload the save afterwards to undo it.
3. To see a greyed-out unit, in `GameCore_Tuner`, send `Players[0]:GetCities():FindID(<cityID>):ChangePopulation(-2)` to a city with 3 population, so the settler needs more population. Send `ChangePopulation(2)` afterwards.
4. To test a choices file that the `.modinfo` doesn't list yet, without a restart, send the file's code without its comments and `include` lines to `SentientSystemsCore_UI`, then the choices file's code the same way. Windows limits a command line to 8,191 characters, so pass long code to the sending script in a file.
5. Read `SentientSystems_GetChoices(Game.GetLocalPlayer())` with `npm run state`, which prints it after the state.

## Results

A single-player game with Gathering Storm, on turn 14, with one city, Rome, at 3 population, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| `SentientSystems_GetChoices` with no choice yet, through `npm run state` | `{}` after the state, 2 bytes. `npm run state -- 99` printed `The core mod failed to build the state: no player 99`, then the same for the choices |
| Units the panel's checks list for Rome | Settler, 40 cost and 6 turns, builder, 25 and 4, scout, 15 and 2, warrior, 20 and 3, and slinger, 17 and 2. None greyed out, none with progress, and no corps or army |
| The settler with Rome at 1 population | Listed, and greyed out with one reason, `This city needs at least 2 [ICON_Citizen] Population.`, as a string. `Locale.Lookup` returned the same text |
| `SentientSystems_GetChoices` with the production choice, through `npm run state` | The five units, 273 bytes |
| The same with Rome at 1 population | The settler with `blocked` and that reason, and 9 turns. The other units took 1 more turn each |
| Buildings the panel's checks list for Rome, after `SetTech` for Pottery and Masonry | Granary, 32 cost and 5 turns, and walls, 40 and 6, both in `DISTRICT_CITY_CENTER`. Neither greyed out nor pillaged. The Pyramids, 110 and 18, and the Great Bath, 90 and 14, were wonders, greyed out with `No suitable location to construct this.` |
| `SentientSystems_GetChoices` with buildings, through `npm run state` | The granary and the walls, and the battering ram that Masonry adds to the units. 499 bytes |
| Districts the panel's checks list for Rome, after `SetTech` for Writing and Astrology | The campus and the holy site, each 29 cost and 6 turns, not greyed out. Each had the tiles (17,13), (16,14), and (16,15), and 8 tiles to buy. The campus had +1 science at (17,13) and (16,15), and +3 science at (19,14), a tile to buy. The city center was left out as built |
| Wonders with Writing | Stonehenge, the Pyramids, the Great Bath, and Etemenanki, with no tile in Rome's territory and one tile to buy each, and none greyed out |
| `SentientSystems_GetChoices` with districts and wonders | 1,692 bytes |
| `SentientSystems_GetPlacement` through `readPlacement`, for Rome | The campus had the same 3 tiles and 8 tiles to buy, with the same bonuses, 335 bytes. The Pyramids had no tile and 1 tile to buy, (17,17), 46 bytes. The granary raised `BUILDING_GRANARY isn't a district or a wonder`, and city 7 raised `no city 7 for player 0` |
| `SentientSystems_GetChoices` without the tiles | 830 bytes, down from 1,692 |
| Rome's production panel with districts and wonders | The holy site and the campus at 6 turns, after **City Center** with a checkmark, and the Great Bath and Stonehenge at 14 and the Pyramids and Etemenanki at 18, none greyed out, as in the choices |
| Rome's production panel against the choices | The same buildings and units with the same turns: walls 6 and granary 5 under **City Center**, and settler 6, builder 4, scout 2, warrior 3, slinger 2, and battering ram 5. The panel sorts the walls before the granary, and the choices keep the game's order. The panel doesn't show cost |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
