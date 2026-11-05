# End-turn blockers

Status: open. The end-turn blockers in `SentientSystems_GetState` are confirmed in a running game. The list of `EndTurnBlockingTypes` values is confirmed in files and in a running game.

The calls the state serializer uses to list what blocks the end of one player's turn, and the screen that resolves each blocker. The choices that resolve them are in the [choices index](../choices/README.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

1. Does `GetFirstEndTurnBlocking` ever return `ENDTURN_BLOCKING_CITY_RANGE_ATTACK`, `ENDTURN_BLOCKING_DISTRICT_RANGE_ATTACK`, or `ENDTURN_BLOCKING_UNIT_PROMOTION`? No UI file names them.

## What we know now

### End-turn blockers

`NotificationManager.GetFirstEndTurnBlocking(playerID)` returns one value of `EndTurnBlockingTypes`. Each value is a hash, such as -286188551 for `ENDTURN_BLOCKING_RESEARCH`, not an index, so the name comes from a reverse lookup in the table. Confirmed on Windows on 2026-10-24. See [ending the turn](../actions/end-turn.md#ending-the-turn). For `ENDTURN_BLOCKING_UNITS`, `ENDTURN_BLOCKING_STACKED_UNITS`, and `ENDTURN_BLOCKING_UNIT_NEEDS_ORDERS`, `DoEndTurn` in `Base/Assets/UI/ActionPanel.lua` calls `UI.SelectNextReadyUnit()`. For any other blocker, it finds the blocker's notification with `NotificationManager.FindEndTurnBlocking(blocker, playerID)` and activates it, and the notification's handler opens the screen. `DoEndTurn` is at lines 526 to 600. Each blocker's prompt text and notification icon are in `g_kMessageInfo` in `ActionPanel.lua`, lines 99 to 115, and in the expansions' replacements of it. The handlers are in `Base/Assets/UI/Panels/NotificationPanel.lua`, lines 200 to 221, and in its replacements. Confirmed in files.

`NotificationManager.GetAllEndTurnBlocking(playerID)` returns a list of every blocker, in the order the game resolves them, and its first entry is the value `GetFirstEndTurnBlocking` returns. A blocker appears once for each of its notifications, and `GetNumNotificationsOfActiveBlocker` in `ActionPanel.lua`, lines 465 to 477, counts the repeats. `ActionPanel.lua` reads the list at lines 166 and 468. Confirmed in files and on Windows on 2026-10-24.

- **Notifications.** `NotificationManager.FindEndTurnBlocking(blocker, playerID)` returns the blocker's notification. Its `GetTypeName()` is the notification type, such as `NOTIFICATION_CHOOSE_TECH`, and `GetMessage()` the text, such as `Choose a Technology`. The production blocker's notification doesn't name a city: `GetLocation()` returned -9999 and -9999. Confirmed on Windows on 2026-10-24.
- **Units that need orders.** `unit:IsReadyToSelect()` is `true` for a unit with moves left and no standing order. The unit flags dim each unit for which it is `false`, in `UnitFlagManager.lua`, line 380. A warrior with 2 moves left read `true`, and `false` once fortified, with its moves unchanged. `player:GetUnits():GetFirstReadyUnit()` returns the first such unit, and `IsReadyToMove()` gave the same answers. Confirmed in files and on Windows on 2026-10-24.
- **Unit blockers update on game events only.** After `UnitManager.RestoreMovement` in `GameCore_Tuner` gave the scout 3 moves, `IsReadyToSelect()` was `true`, but `GetAllEndTurnBlocking` listed no unit blocker. Confirmed on Windows on 2026-10-24.

When nothing blocks, `DoEndTurn` still selects the next unit with moves left, and then a city that can make a ranged attack, before it ends the turn. These prompts don't stop `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`. Confirmed in files.

The table has 30 values in a game with Gathering Storm. `NO_ENDTURN_BLOCKING`, which is 0, means nothing blocks. The UI files name 26 others, and each has a screen, listed here with the expansion each one needs. An expansion's file is in `DLC/Expansion1/UI` for Rise and Fall, and Gathering Storm has its own copy in `DLC/Expansion2/UI`. Confirmed in files:

| Blocker | Screen that resolves it | Needs |
| --- | --- | --- |
| `ENDTURN_BLOCKING_UNITS` | None. `UI.SelectNextReadyUnit()` selects the next unit with moves left | Base game |
| `ENDTURN_BLOCKING_UNIT_NEEDS_ORDERS` | None, as for `ENDTURN_BLOCKING_UNITS` | Base game |
| `ENDTURN_BLOCKING_STACKED_UNITS` | None, as for `ENDTURN_BLOCKING_UNITS`. The prompt asks to move a unit off a tile it shares | Base game |
| `ENDTURN_BLOCKING_PRODUCTION` | `Base/Assets/UI/Panels/ProductionPanel.lua` | Base game |
| `ENDTURN_BLOCKING_RESEARCH` | `Base/Assets/UI/Choosers/ResearchChooser.lua` | Base game |
| `ENDTURN_BLOCKING_CIVIC` | `Base/Assets/UI/Choosers/CivicsChooser.lua` | Base game |
| `ENDTURN_BLOCKING_FILL_CIVIC_SLOT` | The policies tab of `Base/Assets/UI/Screens/GovernmentScreen.lua` | Base game |
| `ENDTURN_BLOCKING_CONSIDER_GOVERNMENT_CHANGE` | The governments tab of `GovernmentScreen.lua` | Base game |
| `ENDTURN_BLOCKING_CONSIDER_RAZE_CITY` | `Base/Assets/UI/Popups/RazeCity.lua` | Base game |
| `ENDTURN_BLOCKING_PANTHEON` | `Base/Assets/UI/Choosers/PantheonChooser.lua` | Base game |
| `ENDTURN_BLOCKING_RELIGION` | `Base/Assets/UI/ReligionScreen.lua` | Base game |
| `ENDTURN_BLOCKING_BELIEF` | `ReligionScreen.lua` | Base game |
| `ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN` | The envoys view of `Base/Assets/UI/PartialScreens/CityStates.lua` | Base game |
| `ENDTURN_BLOCKING_CLAIM_GREAT_PERSON` | `Base/Assets/UI/Popups/GreatPeoplePopup.lua` | Base game |
| `ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE` | `Base/Assets/UI/Popups/EspionageEscape.lua` | Base game |
| `ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY` | `EspionageEscape.lua`, through the same handler as the escape route | Base game |
| `ENDTURN_BLOCKING_ARTIFACT` | `Base/Assets/UI/Popups/ChooseArtifact.lua` | Base game |
| `ENDTURN_BLOCKING_GOVERNOR_APPOINTMENT` | `GovernorPanel.lua` | Rise and Fall |
| `ENDTURN_BLOCKING_GOVERNOR_OPPORTUNITY` | `GovernorPanel.lua` | Rise and Fall |
| `ENDTURN_BLOCKING_GOVERNOR_PROMOTION` | `GovernorPanel.lua` | Rise and Fall |
| `ENDTURN_BLOCKING_GOVERNOR_IDLE` | `GovernorPanel.lua` | Rise and Fall |
| `ENDTURN_BLOCKING_CONSIDER_DISLOYAL_CITY` | `DisloyalCityChooser.lua` | Rise and Fall |
| `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION` | `WorldCrisisPopup.lua` | Rise and Fall |
| `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE` | `EraReviewPopup.lua`, where the player picks an era dedication | Rise and Fall |
| `ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK` | `WorldCongressPopup.lua`, at a special session | Gathering Storm |
| `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` | `WorldCongressPopup.lua`, at a regular session | Gathering Storm |

No UI file names the other three values, `ENDTURN_BLOCKING_CITY_RANGE_ATTACK`, `ENDTURN_BLOCKING_DISTRICT_RANGE_ATTACK`, and `ENDTURN_BLOCKING_UNIT_PROMOTION`, so none of them has a prompt or a screen. Confirmed in files and on Windows on 2026-10-24.

## Method

1. To list the values of `EndTurnBlockingTypes` in a running game, send `for k, v in pairs(EndTurnBlockingTypes) do print(v, k) end` to `SentientSystemsCore_UI`, and compare them with the table in [end-turn blockers](#end-turn-blockers).
2. Read the state as in [state/state.md](state.md#method), step 2.

## Results

A single-player game on a 44 by 26 map, in `SentientSystemsCore_UI`.

`EndTurnBlockingTypes` in `SentientSystemsCore_UI`, in a game with Gathering Storm:

| Check | Result |
| --- | --- |
| Values in the table | 30. The 27 that the UI files name, and `ENDTURN_BLOCKING_CITY_RANGE_ATTACK` 103424869, `ENDTURN_BLOCKING_DISTRICT_RANGE_ATTACK` -76578136, and `ENDTURN_BLOCKING_UNIT_PROMOTION` 1706768628 |
| `GetFirstEndTurnBlocking(Game.GetLocalPlayer())` | -286188551, `ENDTURN_BLOCKING_RESEARCH` |
| `GetAllEndTurnBlocking` on turn 14 | Research, civic, production, and fill civic slot, each once |
| `SentientSystems_GetBlockerState`, after a tech was picked, with the scout's moves restored | `{"list":[{"choice":"civics","type":"ENDTURN_BLOCKING_CIVIC"},{"choice":"production","type":"ENDTURN_BLOCKING_PRODUCTION"},{"choice":"policies","type":"ENDTURN_BLOCKING_FILL_CIVIC_SLOT"}],"units":[196608]}`. `GetFirstEndTurnBlocking` returned `ENDTURN_BLOCKING_CIVIC`, and the **Next Turn** button showed **Choose Civic** |
| `npm run state` after a restart and a reload of the same save, with both units out of moves | Research, civic, production, and fill civic slot, with `techs`, `civics`, `production`, and `policies`, and no units. The state was 14,137 bytes. On turn 15 of a reload, with 100 faith from the tuner on turn 14, `SentientSystems_GetBlockerState` added the pantheon blocker, with `pantheon` |

Date checked: game files on 2026-10-24. Running game on Windows on 2026-10-24, and the choices for the blockers on 2026-10-26.
