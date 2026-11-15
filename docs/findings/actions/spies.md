# Spy actions

Status: open. Starting a mission, a counterspy mission, and a trip, and choosing an escape route, are confirmed in a running game with Gathering Storm, with the files sent through the tuner.

So are the mission popup and what a finished mission gives. A dragnet priority has never come up, so its request is confirmed only in files.

The game calls the spy actions wrap, with the Lua state each runs in and the reasons their checks give. The cities and missions a spy can choose are in [choices/spy-missions.md](../choices/spy-missions.md), and the escape routes in [choices/spies.md](../choices/spies.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other unit actions are in the [actions index](README.md).

## Questions

None open.

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

### Mission popup

`Events.SpyMissionCompleted(playerID, missionID)` fires for every player's finished missions, with the player's turn active.

`Players[playerID]:GetDiplomacy():GetMission(playerID, missionID)` returns the mission's history: `Operation`, `CityName`, `PlotIndex`, `Name` of the spy, `InitialResult`, `EscapeResult`, `LootInfo`, `LevelAfter`, and `CompletionTurn`.

`ShowMissionCompletedPopup` in `EspionagePopup.lua` queues the popup for the local player's missions only. It skips a counterspy mission that ends outside the player's turn. A mission that ends while the popup shows waits in the popup's own list, which only its `Close` opens. Confirmed in files.

The popup shows the outcome, its text, and the rewards, such as a promotion or the loot. Its OK is `MissionSucceedButton` or `MissionFailureButton`, and each runs `Close`, which dequeues it. Only a Listening Post or counterspy mission shows **Renew**.

It holds nothing. A turn ended with the popup open, and the next turn began. With the core mod's dequeue, the same mission left the popup out of the queue and hidden when turn 117 began, with its outcome text filled, and the log had no error. Confirmed on Windows on 2026-11-15.

### Travel

`TeleportToSelectedCity` in `EspionageChooser.lua` checks `CanStartOperation(spy, SPY_TRAVEL_NEW_CITY, plot, params)` with `PARAM_X` and `PARAM_Y` of the city, and requests it with the same parameters.

A city of the player's that the spy stands in opens the counterspy list instead, so the action refuses it. Confirmed in files.

### Escape route

`OnButton1` to `OnButton4` in `Base/Assets/UI/Popups/EspionageEscape.lua` each send `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.SET_ESCAPE_ROUTE, parameters)`, with the route's district index in `PARAM_DISTRICT_TYPE`.

No spy is sent, because the game takes the route for the next escaping spy.

The dragnet priority blocker opens the same screen, so it would send the same request. See [choices/spies.md](../choices/spies.md#escape-screen). Confirmed in files.

The action reads the spy and its routes with `SentientSystems_GetNextEscape`, only while a spy blocker is up, so it never calls `GetNextEscapingSpyID` with no spy escaping, which crashed the game.

It refuses a route the screen turns off, with the screen's own text, since the game's own check on the request isn't known.

Within 2 seconds of the request, in `SentientSystemsCore_UI`, `ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE` was gone, the spy was no longer on the map, and the player's `GetNumSpiesOffMap()` went up by 1. Confirmed on Windows on 2026-11-11.

## Method

1. Send the files' code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4. Call `SentientSystems_SpyMission(playerID, unitID, mission, district)` and `SentientSystems_SpyTravel(playerID, unitID, ownerID, cityID)`.
2. For an escape route, load a save with `ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE` up, send `Scripts/SentientSystemsCore_Espionage.lua` too, and call `chooseEscapeRoute` from the bridge.
3. To get a ready spy, send `UnitManager.InitUnit(0, "UNIT_SPY", x, y)` in `GameCore_Tuner` on a city's tile. It ignores the spy capacity. To put a spy in another player's city, see [choices/spy-missions.md](../choices/spy-missions.md#method).

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

A single-player game with Gathering Storm on turn 92, where Chloe escaped Patna, player 9's city, with 220 Gold, chased by the police. Vehicle and Foot were open, and Airplane and Boat were off:

| Call | Result |
| --- | --- |
| `chooseEscapeRoute` with `DISTRICT_HARBOR` | `No Harbor in city` |
| `chooseEscapeRoute` with `DISTRICT_CAMPUS` | `DISTRICT_CAMPUS isn't an escape route. Use one of DISTRICT_COMMERCIAL_HUB, DISTRICT_CITY_CENTER.` |
| `chooseEscapeRoute` with `DISTRICT_COMMERCIAL_HUB` | `{"ok":true}`. The blocker cleared, the spy left the map, and the spies off the map went from 3 to 4 |
| `SentientSystems_ChooseEscapeRoute` with `DISTRICT_CITY_CENTER` again | `You have no spy escaping. The spies choice lists one when a spy is caught.` |

A single-player game with Gathering Storm on turn 116, in `SentientSystemsCore_UI`, with a listener printing each `SpyMissionCompleted` and the mission's history:

| Call | Result |
| --- | --- |
| `SentientSystems_EndTurn(0, true)` on turn 116 | Missions of players 1 and 6 ended, then on turn 117 Siphon Funds of player 0 with `InitialResult` 5 and `LootInfo` 300. The popup showed **SUCCESS!**, 300 Gold, and a promotion |
| The same on turn 117, with the popup open | The AI turns waited on a friendship request from player 6, not the popup. After `SentientSystems_RespondToSession(0, 6, "CHOICE_NEGATIVE")`, turn 118 began |
| The same on turn 118, with a failed Sabotage Production popup open | Turn 119 began with the popup still open |
| `DoLeftClick()` on the hidden `MissionSucceedButton` of the failure popup | The popup left the queue and hid |
| `SentientSystems_EndTurn(0, true)` on turn 116 again, with the core mod's dequeue | Turn 117 began with the popup out of the queue and hidden, and its text held the 300 Gold outcome |

Date checked: game files on 2026-11-06, 2026-11-11, and 2026-11-15. Running game on Windows on 2026-11-06, 2026-11-11, and 2026-11-15.
