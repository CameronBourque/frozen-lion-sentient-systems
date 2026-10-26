# Game choices

Status: open. `SentientSystems_GetChoices` with the units each city can train is confirmed in a running game. Corps and armies are confirmed in files only.

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
- **Heroes and Legends.** The game mode replaces the panel with `DLC/Babylon/UI/Replacements/ProductionPanel_Babylon_Heroes.lua`. The choices don't follow that file. Confirmed in files.

## Method

1. In `SentientSystemsCore_UI`, loop over `GameInfo.Units()` for each city with the checks above, and compare the list with the production panel.
2. To see a greyed-out unit, in `GameCore_Tuner`, send `Players[0]:GetCities():FindID(<cityID>):ChangePopulation(-2)` to a city with 3 population, so the settler needs more population. Send `ChangePopulation(2)` afterwards.
3. To test a choices file that the `.modinfo` doesn't list yet, without a restart, send the file's code without its comments and `include` lines to `SentientSystemsCore_UI`, then the choices file's code the same way.
4. Read `SentientSystems_GetChoices(Game.GetLocalPlayer())` with `npm run state`, which prints it after the state.

## Results

A single-player game with Gathering Storm, on turn 14, with one city, Rome, at 3 population, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| `SentientSystems_GetChoices` with no choice yet, through `npm run state` | `{}` after the state, 2 bytes. `npm run state -- 99` printed `The core mod failed to build the state: no player 99`, then the same for the choices |
| Units the panel's checks list for Rome | Settler, 40 cost and 6 turns, builder, 25 and 4, scout, 15 and 2, warrior, 20 and 3, and slinger, 17 and 2. None greyed out, none with progress, and no corps or army |
| The settler with Rome at 1 population | Listed, and greyed out with one reason, `This city needs at least 2 [ICON_Citizen] Population.`, as a string. `Locale.Lookup` returned the same text |
| `SentientSystems_GetChoices` with the production choice, through `npm run state` | The five units, 273 bytes |
| The same with Rome at 1 population | The settler with `blocked` and that reason, and 9 turns. The other units took 1 more turn each |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
