# Game espionage in the state

Status: open. The `espionage` section of `SentientSystems_GetState` is confirmed in a running game for every kind of spy, the other majors' cities, and the mission history, with a great work as loot. A tech as loot and an enemy spy that the player holds haven't been seen live.

The calls the espionage in the state uses, as the three tabs of the Espionage screen show them. The spy missions and escape routes are in [choices/spy-missions.md](../choices/spy-missions.md) and [choices/spies.md](../choices/spies.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

1. Does the section match the tabs for a mission that stole a tech, and for an enemy spy that the player holds? No civ has a spy, and a spawned one never started a mission, so the second needs the AI to send one.

## What we know now

### Operatives tab

`Base/Assets/UI/PartialScreens/EspionageOverview.lua` draws the screen, and no expansion replaces it. `RefreshOperatives`, lines 72 to 152, lists the spies in this order. Confirmed in files.

- **Idle and active.** Every unit of the player whose `GameInfo.Units` row has `Spy`, idle ones first. A spy is idle when `GetSpyOperation()` is -1.

  `AddOperative` shows the name, the rank from `GetExperience():GetLevel()` as `LOC_ESPIONAGE_LEVEL_<level>_NAME`, and the city that owns the spy's tile, from `Cities.GetPlotPurchaseCity`.

  A mission has `GameInfo.UnitOperations[operation]`, its `OperationType` and `Description`, the turns left as `GetSpyOperationEndTurn()` less the current turn, never below 0, and the whole time from `UnitManager.GetTimeToComplete(operation, spy)`.
- **Captured.** Each player's `GetDiplomacy():GetNthCapturedSpy(playerID, i)`, for `GetNumSpiesCaptured()` spies, whose `OwningPlayer` is the local player. A spy has `Name`, `Level`, and `NameIndex`, the value that a deal to get it back uses.
- **Traveling.** `GetDiplomacy():GetNthOffMapSpy(playerID, i)`, for `GetNumSpiesOffMap()` spies, skipping a `ReturnTurn` of -1. A spy has `Name`, `Level`, `XLocation`, `YLocation`, and `ReturnTurn`, and the turns left are `ReturnTurn` less the current turn.
- **Capacity.** The header shows the number of spies over `GetDiplomacy():GetSpyCapacity()`.

### City Activity tab

`RefreshCityActivity` lists the player's own cities and then those of every other major player, for each city on a revealed tile, with `PlayersVisibility[player]:IsRevealed`. The tab shows no enemy spy. Confirmed in files.

- **Districts.** `AddDistrictIcon` draws each district of `city:GetDistricts():Members()` that `IsComplete()`, except `DISTRICT_WONDER`. A district also shows the player's spy that works in it, from the spy's tile `GetDistrictID()`.
- **Boost.** `GetDiplomacy():GetSourceTurnsRemaining(city)` above 0 shows the Gain Sources boost icon.
- **Counterspy.** The counterspy icon reads `shouldShowCounterspyIcon`, which nothing sets, so it never shows.
- **Own cities.** The state's cities section already has them with their districts, and the rivals section has no districts, so the state adds the other majors' cities here.

### Mission History tab

`RefreshMissionHistory`, lines 186 to 240, shows two things. Confirmed in files.

- **Held spies.** `GetNthCapturedSpy(localPlayerID, i)` for the player's own `GetNumSpiesCaptured()` are the other players' spies that the player holds, with `OwningPlayer`, `Name`, `Level`, and the `NameIndex` that a deal to trade one back uses.
- **Missions.** `GetRecentMissions(localPlayerID, 10, 0)` returns up to 10 missions, or nothing, each with `Name`, `LevelAfter`, `Operation`, `CompletionTurn`, `InitialResult`, `EscapeResult`, `LootInfo`, `CityName`, and `PlotIndex`.

  The screen lists them in the order the game gives, and skips a mission whose spy must escape and has no `EscapeResult` yet.

`GetMissionOutcomeDetails` in `EspionageSupport.lua` turns the two results into a success, the spy's fate, and a sentence. A counterspy is always a success. A spy that was detected and killed or captured is a failure even when the mission was done.

`EspionageResultTypes` are `KILLED` 0, `CAPTURED` 1, `FAIL_MUST_ESCAPE` 2, `FAIL_UNDETECTED` 3, `SUCCESS_MUST_ESCAPE` 4, `SUCCESS_UNDETECTED` 5, and `NO_RESULT` -1. `InitialResult` has the mission's result and `EscapeResult` what became of a detected spy.

The sentence is `LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_` plus the outcome, with `_STOLELOOT` added when `LootInfo` is 0 or more. A detected success that escaped is the one exception: its loot sentence has no `ESCAPED`. `LootInfo` is a tech, a great work, or the gold of **Siphon Funds**.

## Method

1. To read a state section that the `.modinfo` doesn't load yet, send the code as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_GetEspionageState(Players[Game.GetLocalPlayer()])` in `SentientSystemsCore_UI`, printing the result with `SentientSystems_EncodeJson`.
2. To get an idle spy, see [choices/spies.md](../choices/spies.md#method), step 2. In `GameCore_Tuner`, `UnitManager.InitUnit(0, "UNIT_SPY", x, y)` on a rival city's center tile also lets it start missions at once. `UnitManager.Kill(unit)` removes one.
3. To promote a spy, in `GameCore_Tuner` call `GetExperience():ChangeExperience(300)` and `SetPromotion(GameInfo.UnitPromotions[type].Index)` for each of `PROMOTION_SPY_TECHNOLOGIST`, `PROMOTION_SPY_CAT_BURGLAR`, and the rest.

   The experience doesn't raise the level, but the promotions apply. `GameInfo` rows can't be listed in that state, so read them in `SentientSystemsCore_UI`.
4. To start a mission, only the player's own spy can, from `SentientSystemsCore_UI` or the screen.

   `UnitManager.RequestOperation` ignores a spy of another player, and a spy spawned for an AI player never started a mission in 5 turns. `GetSpyCapacity()` was 0 to 2 for every civ, none had a spy or an Intelligence Agency, and the AI didn't build any.
5. Steal Tech Boost needs a tech that the target has, the player lacks, and whose boost isn't triggered.

   A triggered boost can't be cleared, so `GetTechs():SetTech(index, false)` on an untriggered one, such as `TECH_MINING`, made it possible.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The section with one spy on a mission and one traveling | Capacity 3. Jakob, a recruit on **Gain Sources** in Patna, with 3 of 4 turns left, and Axrotalus, a recruit traveling to Aduatuca with 2 turns left. The player had 1 spy unit and 1 spy off the map |
| The other majors' cities | 34 cities in 3,940 bytes with the operatives. Mbanza Kongo had its city center, campus, commercial hub, industrial zone, and entertainment complex, and a Gain Sources boost with 6 turns left, as the tab showed. A spy on a mission worked in the city center |
| The mission history | The 3 missions of the tab: Axrotalus took 76 gold from Mbanza Kongo and escaped 2 turns ago, Luguselwa was killed in Caguana 17 turns ago, and Luguselwa was caught in Ahtahkakoop 30 turns ago, each sentence as the tab worded it. The whole section was 4,860 bytes |
| A heist that took a great work | Margot, undetected in Mikisiw-Wacîhk: success, no fate, the loot `Heroides`, and "Stole Heroides from the city of Mikisiw-Wacîhk undetected." |
| A mission whose detected spy was killed | Kunopennos in Mikisiw-Wacîhk: failure, fate `killed`. Jakob in Patna: a done mission, failure, fate `killed`, as the tab words it |
| A mission that failed undetected, and a counterspy | Aia failed a tech steal undetected. Boudica's counterspy found no spy, and the section calls it a success |
| A spy of the player that was captured | Aia was caught on her next tech steal. The history shows failure with fate `captured`, and `operatives` lists her as `captured`, held by player 1, with deal index 19. `captives` stayed empty |
| A spy spawned in Aduatuca with `UnitManager.InitUnit` | Boudica, a recruit, idle in Aduatuca, listed before the spy on a mission |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
