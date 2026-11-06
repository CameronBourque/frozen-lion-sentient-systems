# Spy actions

Status: open. Starting a mission, a counterspy mission, and a trip are confirmed in a running game with Gathering Storm, with the files sent through the tuner. What the missions give when they finish is not checked.

The game calls the spy actions wrap, with the Lua state each runs in and the reasons their checks give. The cities and missions a spy can choose are in [choices/spy-missions.md](../choices/spy-missions.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other unit actions are in the [actions index](README.md).

## Questions

1. What does a mission give when it ends, and does renewing a Listening Post with no parameters work as the popup's **Renew**, which passes the city's `PARAM_X` and `PARAM_Y`? Gain Sources and the counterspy mission were started, and none had finished.

## What we know now

### Missions

`OnAccept` in `Base/Assets/UI/Popups/EspionagePopup.lua` requests an offensive mission with `UnitManager.RequestOperation(spy, hash)` and no parameters.

`OnCounterspySelected` in `EspionageChooser.lua` requests `UnitOperationTypes.SPY_COUNTERSPY` with `PARAM_X` and `PARAM_Y` of the district's tile. Confirmed in files.

- The action starts a mission by its operation type from the choice, such as `UNITOPERATION_SPY_SIPHON_FUNDS`, and a counterspy mission with the district's type, such as `DISTRICT_COMMERCIAL_HUB`.
- A spy takes an order only when it `IsReadyToMove()` and is awake, as the chooser opens only then. A spy on a mission or on its way is not ready.
- The reasons come from the choice's list: a spy in no city, a mission the spy can't start with the types it can start, and the game's own reasons for a mission it lists as disabled.
- Only a counterspy mission needs a district. Each offensive mission has one `TargetDistrict` in `UnitOperations.xml`, so a city has one target for it.

  Disrupt Rocketry targets the spaceport, Great Work Heist the theater, Recruit Partisans the neighborhood, Sabotage Production the industrial zone, Siphon Funds the commercial hub, and Steal Tech Boost the campus. The others use the city center.
- A finished mission shows a result in the mission popup. Only Listening Post and a counterspy mission can be renewed there, by `RenewMission`, which requests the same operation again with the target plot.

  A spy that is caught or must escape raises the escape route blocker, which the [spy choice](../choices/spies.md) and the espionage blocker step cover.

### Travel

`TeleportToSelectedCity` in `EspionageChooser.lua` checks `CanStartOperation(spy, SPY_TRAVEL_NEW_CITY, plot, params)` with `PARAM_X` and `PARAM_Y` of the city, and requests it with the same parameters.

A city of the player's that the spy stands in opens the counterspy list instead, so the action refuses it. Confirmed in files.

## Method

1. Send the files' code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4. Call `SentientSystems_SpyMission(playerID, unitID, mission, district)` and `SentientSystems_SpyTravel(playerID, unitID, ownerID, cityID)`.
2. To get a ready spy, send `UnitManager.InitUnit(0, "UNIT_SPY", x, y)` in `GameCore_Tuner` on a city's tile. It ignores the spy capacity. To put a spy in another player's city, see [choices/spy-missions.md](../choices/spy-missions.md#method).

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| A spy in Pihtokahanapiwiyin, a city of player 1, for Gain Sources | `{"ok":true}`. The spy's operation became 41, and its end turn 60. It then wasn't ready, and a second request said so |
| The same spy for Steal Tech Boost, a move, and a name that is no operation | The reasons named the five missions it could start, and said the others aren't spy missions |
| A knight, a spy on a mission, and a unit that doesn't exist | "This kind of unit isn't a spy.", "The spy is on a mission or on its way.", and "Player 0 has no unit 99999." |
| A new spy in Bibrax, a city of the player's, for a counterspy mission with no district | The reason named the six districts |
| The same for a counterspy mission at Commercial Hub | `{"ok":true}`. The spy's operation became 39 and its end turn 64 |
| A new spy sent to Bibrax, where it stood, and to Aduatuca | "The spy is already in Bibrax.", then `{"ok":true}`, and the player's `GetNumSpiesOffMap()` went to 2 |
| A trip to a city that doesn't exist | "Player 40 has no city 1." |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
