# Game espionage in the state

Status: open. The `espionage` section of `SentientSystems_GetState`, the spy capacity and the player's spies, is confirmed in a running game for an idle spy, a spy on a mission, and a traveling spy. A captured spy hasn't been seen live.

The calls the espionage in the state uses, as the Operatives tab of the Espionage screen shows them. The spy missions and escape routes are in [choices/spy-missions.md](../choices/spy-missions.md) and [choices/spies.md](../choices/spies.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

1. Does the section match the Operatives tab for a captured spy, whose calls haven't returned one live?

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

## Method

1. To read a state section that the `.modinfo` doesn't load yet, send the code as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_GetEspionageState(Players[Game.GetLocalPlayer()])` in `SentientSystemsCore_UI`, printing the result with `SentientSystems_EncodeJson`.
2. To get an idle spy, see [choices/spies.md](../choices/spies.md#method), step 2.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The section with one spy on a mission and one traveling | Capacity 3. Jakob, a recruit on **Gain Sources** in Patna, with 3 of 4 turns left, and Axrotalus, a recruit traveling to Aduatuca with 2 turns left. The player had 1 spy unit and 1 spy off the map |
| The other majors' cities | 34 cities in 3,940 bytes with the operatives. Mbanza Kongo had its city center, campus, commercial hub, industrial zone, and entertainment complex, and a Gain Sources boost with 6 turns left, as the tab showed. A spy on a mission worked in the city center |
| A spy spawned in Aduatuca with `UnitManager.InitUnit` | Boudica, a recruit, idle in Aduatuca, listed before the spy on a mission |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
