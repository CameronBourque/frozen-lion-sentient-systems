# Production choices

Status: open. `SentientSystems_GetChoices` with the units, buildings, wonders, and projects each city can produce is confirmed in a running game. The districts are in [choices/districts.md](districts.md). Corps and armies are confirmed in files only.

The calls the production choice uses to list what each city can produce, as the production panel lists them. The other choices are in the [choices index](README.md). The end-turn blockers that the choices resolve are in [state/state.md](../state/state.md#end-turn-blockers). See [design/core/mod/choices.md](../../design/core/mod/choices.md).

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
- **Wonders.** A wonder's row has `IsWonder` set to `true`, and no `PrereqDistrict`. The panel lists it with the same checks as a building, and greys it out as [placement tiles](placement.md#placement-tiles) describes. Confirmed in files and on Windows on 2026-10-26.
- **Turns that never end.** The panel shows `999+` and `TXT_HUD_CITY_WILL_NOT_COMPLETE` when `GetTurnsLeft` returns -1, in `PopulateDistrictsWithNestedBuildings`, lines 961 to 964. Confirmed in files.

### Projects

`GetData` in `ProductionPanel.lua`, lines 2208 to 2239, builds the panel's project list from `GameInfo.Projects()`. The panel lists a project when `buildQueue:CanProduce(row.Hash, true)` returns `true`, and greys it out when `CanProduce(row.Hash, false, true)` returns `false`, with the reasons in `results[CityCommandResults.FAILURE_REASONS]`. It reads `GetProjectCost(row.Index)`, `GetProjectProgress(row.Index)`, and `GetTurnsLeft(row.ProjectType)`, and marks a project repeatable when `row.MaxPlayerInstances` isn't 1. It lists the project in production too. Campus Research Grants, `PROJECT_ENHANCE_DISTRICT_CAMPUS`, had no `MaxPlayerInstances`. Confirmed in files and on Windows on 2026-10-26.


### Other modes

- **Heroes and Legends.** The game mode replaces the panel with `DLC/Babylon/UI/Replacements/ProductionPanel_Babylon_Heroes.lua`. The choices don't follow that file. Confirmed in files.

## Method

1. In `SentientSystemsCore_UI`, loop over `GameInfo.Units()` and `GameInfo.Buildings()` for each city with the checks above, and compare the lists with the production panel.
2. To unlock buildings and districts in an early game, in `GameCore_Tuner`, send `Players[0]:GetTechs():SetTech(GameInfo.Technologies["TECH_POTTERY"].Index, true)`, and the same for `TECH_MASONRY`, `TECH_WRITING`, and `TECH_ASTROLOGY`. To add a district without producing it, in `GameCore_Tuner`, send `WorldBuilder.CityManager():CreateDistrict(city, GameInfo.Districts["DISTRICT_CAMPUS"].Index, 100, Map.GetPlot(x, y):GetIndex())`, as `DLC/BlackDeathScenario` does. To remove one, send `WorldBuilder.CityManager():RemoveDistrict(city:GetDistricts():GetDistrict(<district index>))`. In `GameCore_Tuner`, a city's `GetDistricts()` has no `Members()`. To add a building, send `WorldBuilder.CityManager():CreateBuilding(city, "BUILDING_SHRINE", 100, plotIndex)`. Reload the save afterwards to undo them.
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
| Wonders with Writing | Stonehenge, the Pyramids, the Great Bath, and Etemenanki, with no tile in Rome's territory and one tile to buy each, and none greyed out |
| Projects with a campus that `CreateDistrict` added at (17,13) | Campus Research Grants, 14 cost and 3 turns, repeatable. The campus was left out of the districts as built, the library joined the buildings at 7 turns, and the holy site was greyed out with `Requires [ICON_Citizen] Population of 4 or greater.`. The holy site's cost read 29 right after `CreateDistrict`, and 39 in a later read, as the panel showed. 1,074 bytes |
| Rome's production panel with the campus | The same lists and turns as the choices. **Campus** and **City Center** with checkmarks, the holy site greyed out with the same reason and a cost of 39, as in the choices, and Stonehenge greyed out with `No suitable location to construct this.`, with no tile left after the campus took (17,13). Campus Research Grants at 3 turns, under **Projects** |
| Production for Rome on the same turn | The Gurdwara under the holy site at 15 turns, greyed out with `This building requires a Temple building.`, the campus greyed out with the population reason, and Holy Site Prayers, `PROJECT_ENHANCE_DISTRICT_HOLY_SITE`, at 3 turns and repeatable. The production panel showed the same |
| Rome's production panel against the choices | The same buildings and units with the same turns: walls 6 and granary 5 under **City Center**, and settler 6, builder 4, scout 2, warrior 3, slinger 2, and battering ram 5. The panel sorts the walls before the granary, and the choices keep the game's order. The panel doesn't show cost |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
