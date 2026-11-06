# Game spy missions

Status: open. The `spyMissions` key of `SentientSystems_GetChoices`, the cities a ready spy can travel to and the missions it can start where it stands, is confirmed in a running game with Gathering Storm, with the file sent through the tuner.

The destination list matches the Embed Spy screen, and the mission list matches the Choose Mission screen.

The calls the spy missions choice uses, as the espionage chooser lists them. The escape routes are in [spies.md](spies.md). The other choices are in the [choices index](README.md). See [design/core/mod/choices.md](../../design/core/mod/choices.md).

## Questions

None open.

## What we know now

### Chooser

`Base/Assets/UI/Choosers/EspionageChooser.lua` draws the chooser and `Base/Assets/UI/EspionageSupport.lua` words its stats. Gathering Storm replaces only `RefreshDestinationList`, in `EspionageChooser_Expansion1.lua`, and Rise and Fall's copy is the same.

The mission briefing is `Base/Assets/UI/Popups/EspionagePopup.lua`. Confirmed in files.

- **Which mode.** `GoToProperInterfaceMode` opens the chooser for a spy that `IsReadyToMove()` and is awake. In a city of the player's it opens the destination chooser, **Embed Spy**, and in any other city the mission chooser. A spy on a mission or on its way is not ready.
- **Destinations.** `RefreshDestinationList` walks `Game.GetPlayers()` in ID order, with each player's cities in order. It skips a player in the `DIPLO_STATE_ALLIED` state, a teammate, and the Free Cities, and lists only cities on a tile the player has revealed. City-states are included.
- **Each destination.** The name, with the capital icon for a major civilization's capital, the turns, and the districts. The turns are `UnitManager.GetTravelTime(spy, city)` plus `GetEstablishInCityTime(spy, city)`, and the tooltip gives both.

  The icons are the city's complete districts, with wonders left out.
- **Missions.** `RefreshMissionList` asks `UnitManager.CanStartOperation(spy, hash, cityPlot, false, true)` for each operation. In a city of the player's it lists `UNITOPERATION_SPY_COUNTERSPY`, once for each plot in the results, which is a district.

  Elsewhere it lists each operation with the category `OFFENSIVESPY`.
- **An offensive mission.** An allowed one is listed once for each plot in `UnitOperationResults.PLOTS`, or once for the city center with none. A refused one is listed, disabled, only when the results carry `FAILURE_REASONS`.

  Each shows its name, the target district, `UnitManager.GetTimeToComplete`, the chance from `GetResultProbability`, and the text of `GetFormattedOperationDetailText`, which wraps `UnitManager.GetOperationDetailText` in a `LOC_SPYMISSIONDETAILS_` text for five of them.
- **The briefing.** Accepting calls `UnitManager.RequestOperation(spy, hash)` with no parameters, and a counterspy mission passes the district's `PARAM_X` and `PARAM_Y`.

  The briefing's chances are the success, `ESPIONAGE_SUCCESS_UNDETECTED` plus `ESPIONAGE_SUCCESS_MUST_ESCAPE`, the failure, and the rest as captured or killed, in whole percents.

  It warns that the target will learn who did it, unless the mission is sure or the target can receive influence, which a city-state can.
- **Spies not in `GetUnits()`.** The Espionage screen's **Operatives** tab adds a spy on its way from `GetDiplomacy():GetNumSpiesOffMap()` and `GetNthOffMapSpy`, and a captured spy from each player's `GetNthCapturedSpy`.

  They aren't units, so the choice never lists them. Confirmed in files and in a running game.
- **Travel.** `UNITOPERATION_SPY_TRAVEL_NEW_CITY`, with the destination's `PARAM_X` and `PARAM_Y`, is what the chooser requests.

## Method

1. Send the choice's code to `SentientSystemsCore_UI` as in [production.md](production.md#method), step 4, and print `SentientSystems_EncodeJson(SentientSystems_GetSpyMissionChoices(Players[0]))`.
2. To put a spy in another player's city, send `UnitManager.PlaceUnit(spy, x, y)` in `GameCore_Tuner`, then `UnitManager.RestoreMovement(spy)`.
3. To compare, open the **Embed Spy** screen with the spy selected, and read the destination list. A spy in another player's city opens its mission list.

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The ready spy in Bibrax, a city of the player's | 61 destinations, 6 districts for Bibrax, and 6 counterspy missions in the `CanStartOperation` results. The game's offensive operations all returned `false` |
| The destination list against the **Embed Spy** screen, in screenshots | The same 61 cities in the same order, the same turns, and the same districts for every city checked, such as Thăng Long with seven and Bagacum with seven. The capital icons matched |
| The same spy in Pihtokahanapiwiyin, a city of player 1 | Five missions, 4 turns each: **Gain Sources**, **Listening Post**, **Siphon Funds**, **Foment Unrest**, **Neutralize Governor**. **Siphon Funds** targeted the commercial hub. The others returned `false`, none disabled |
| The chances in that city | **Gain Sources** and **Listening Post** 100%. **Siphon Funds** and **Foment Unrest** 50% success, 34% failure, and 16% captured. **Neutralize Governor** 37%, 36%, and 27%. The game's warning names the owner's leader, who "will lose respect for us" if discovered |
| The open **Choose Mission** screen for that spy, in a screenshot | The same five missions in the same order, with the same targets, 4 turns each, and the same texts. It shows only the success chance, 100%, 100%, 50%, 50%, and 37%. The choice adds the briefing's other chances |
| The **Operatives** tab | Three spies: the one placed in Pihtokahanapiwiyin, "Awaiting Assignment", one on a mission with 3 turns left, and one traveling with 2 turns left, which `GetUnits()` doesn't list |
| The choice's JSON for that spy | 11,025 bytes, and it parsed against the schema |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
