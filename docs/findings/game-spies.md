# Game spies

Status: open. The `spies` key of `SentientSystems_GetChoices`, the escape routes for the player's escaping spy, is confirmed in a running game with Gathering Storm, with the file sent through the tuner, and matches the escape screen. A dragnet priority hasn't been seen in a game.

The calls the spy choice uses, as the escape screen shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does `ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY` open the escape screen with a spy from `GetNextEscapingSpyID`, as the notification panel's handler suggests?

## What we know now

### Escape screen

`Base/Assets/UI/Popups/EspionageEscape.lua` draws the escape screen, and no expansion replaces it. `NotificationPanel.lua`, lines 220 and 221, opens it for both `SPY_CHOOSE_ESCAPE_ROUTE` and `SPY_CHOOSE_DRAGNET_PRIORITY`. Confirmed in files.

- **Spy.** `OnOpen`, lines 36 to 113, finds the spy with the player's `GetDiplomacy():GetNextEscapingSpyID()` and `GetUnits():FindID`, and the city with `Cities.GetPlotPurchaseCity` on the spy's tile. It shows the spy's `GetName()`, `GetLootName()`, and `GetPursuingSpyName()`, which is empty for the police, as `LOC_ESPIONAGE_ESCAPE_PURSUIT_POLICE`, or a counterspy's name, as `LOC_ESPIONAGE_ESCAPE_PURSUIT_COUNTERSPY`. On turn 48, Laurenza escaped from Istanbul, player 4's city, with "None" as loot, chased by the police. Confirmed in files and on Windows on 2026-10-27.
- **Routes.** Lines 71 to 106 show four routes, **Airplane**, **Boat**, **Vehicle**, and **Foot**, which leave by the aerodrome, harbor, commercial hub, and city center. Each open route shows its district's `TravelTime` from `GameInfo.Districts`, 1 to 4, as **Turns to return**, and a route that is off shows `LOC_ESPIONAGE_ESCAPE_NO_DISTRICT` in its place, as the choice does. The first three are off unless the city's `GetDistricts():HasDistrict(index, true, true)` is `true`, and **Foot** is always on. Istanbul had none of the three. The open routes share `LOC_ESPIONAGE_ESCAPE_TOOLTIP`, which says the police watch the quick exits more. Confirmed in files and on Windows on 2026-10-27.
- **Dragnet priority.** It is the defender's side: the game's text calls it **Choose Pursuit Priority**, for when "an enemy Spy has been detected", to choose which escape route to close off with the police. No file of the game's UI handles it apart from the escape screen, which reads the player's own escaping spy, so a defender with none would get no spy there. In many hours of play, with rival spies caught, killed, and let go, it never came up, so it looks unused. Confirmed in files, and by play.
- **Sending.** Each button sends `PlayerOperations.SET_ESCAPE_ROUTE` with the district's index in `PARAM_DISTRICT_TYPE`. Confirmed in files.
- **Crash.** `GetDiplomacy():GetNextPursuedSpyID()`, which the screen never calls, crashed the game with an access violation while a spy was escaping. The choice makes only the calls the screen makes. Confirmed on Windows on 2026-10-27.
- **Left out.** The choice leaves out spies travelling to a city, which are off the map and found with `GetNumSpiesOffMap()` and `GetNthOffMapSpy(i)`, each with `XLocation`, `YLocation`, `ReturnTurn`, `Name`, and `Level`, and the missions of spies in cities. Phase 3 adds spies to the state. Confirmed on Windows on 2026-10-27.

## Method

1. To read a choice that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, and send `SentientSystemsCore_Choices.lua` again so it calls it.
2. To put a spy in a rival city without the trip, send `UnitManager.InitUnit(0, "UNIT_SPY", x, y)` in `GameCore_Tuner` on the city's tile. It could start **Gain Sources**, **Listening Post**, and **Foment Unrest** at once. A spy that is caught after a mission has to escape, which is down to chance.

## Results

A single-player game with Gathering Storm, on turn 48, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The choices with Laurenza escaping Istanbul | One spy, 2555922, with Istanbul, "None", "Police", the shared tooltip, and four routes: Airplane, Boat, and Vehicle each blocked for lack of their district, and Foot open at 4 turns. `ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE` with `"choice":"spies"` |
| The choices through the bridge's readers | Parsed, with the same values |
| The escape screen on the same turn | **Chase Sequence** in Istanbul, with Laurenza, None as loot, and Police. Airplane, Boat, and Vehicle off, with "No Aerodrome in city", "No Harbor in city", and "No Commercial Hub in city", and Foot on, with "Turns to return: 4" |

Date checked: game files on 2026-10-27. Running game on Windows on 2026-10-27.
