# Ending the turn

Status: open. Ending the turn, and the core mod's end turn action, are confirmed in a running game. How the end-turn blockers interact with it is open.

The game call the end turn action wraps, with the Lua state it runs in and where we found it. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).

## Questions

None open. The project built and rock band popups are in [popups.md](popups.md#project-built-popup).

## What we know now

### Ending the turn

`UI.RequestAction(ActionTypes.ACTION_ENDTURN)` ends the turn. It's in `Base/Assets/UI/ActionPanel.lua` at line 512. The base UI calls it in five places. Confirmed in files.

Sent from `SentientSystemsCore_UI` in single player, it ended the turn, and the next `AGENT_TURN` line came 3 s later. Confirmed on Windows on 2026-10-23.

An end-turn blocker doesn't stop the request. `NotificationManager.GetFirstEndTurnBlocking(Game.GetLocalPlayer())` returned `ENDTURN_BLOCKING_RESEARCH`, the **Choose Research** prompt, before and after the turn ended.

`UI.CanEndTurn()` returned `true` with the blocker in place. Confirmed on Windows on 2026-10-23. The base UI checks the blocker itself before it calls `RequestAction`.

`DoEndTurn` in `ActionPanel.lua` ends the turn only when the blocker is `NO_ENDTURN_BLOCKING`. For any other blocker, it selects the next unit or opens the blocking notification. `DoEndTurn` starts at line 526. Confirmed in files.

civ6-mcp ends the turn with the same call, in [`build_end_turn`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/notifications.py#L46). It never sends a second request while the first is still in progress, because a repeated request can skip turns.

Instead, it waits for the turn number to change. See [`end_turn.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/end_turn.py#L1139). Unconfirmed, used by civ6-mcp.

### With a leader screen up

With a leader screen up, the request closes the screen and doesn't end the turn. Twice on turn 85, the request closed the screen, and the turn stayed at 85 with the player's turn active:

- Scythia's comment, with its session open. The request closed the session. See [comments](ai-sessions.md#comments).
- The Netherlands leader's goodbye after `SentientSystems_DeclareWar`, with no session open.

A third request, with only the map up, ended the turn. Confirmed on Windows on 2026-11-13.

### With the wonder built popup up

`Base/Assets/UI/Popups/WonderBuiltPopup.lua` opens for the local player only, from `Events.WonderCompleted`. It isn't an end-turn blocker.

Its `ExclusivePopupManager:Lock`, in `PopupManager.lua`, takes `UI.ReferenceCurrentEvent()`, which holds the engine's event queue until `Close` calls `UI.ReleaseEventID`. Confirmed in files.

The hold, not the `CINEMATIC` interface mode, stops the game. On turn 56, with the popup up:

- A move from `SentientSystems_MoveUnit` returned `{"ok":true}` and didn't move the unit. It moved once the hold was released.
- `SentientSystems_EndTurn(0, true)` returned `{"ok":true}`, and the turn didn't end, before or after the release. The action had recorded the request, so a second call was refused as a turn already ended.
- `AGENT_TURN 0` printed only after the release.

Releasing the event ID from `SentientSystemsCore_UI`, with the other steps of `Close`, closed the popup, and the AI turns ran. Confirmed on Windows on 2026-11-14.

The core mod closes it for an agent player by pressing its `Close` button when the batch of game events ends. See [design/core/mod/README.md](../../design/core/mod/README.md#popups).

`InGame.lua` hides the interface on `WonderBuiltPopup_Shown`, and shows it again on `WonderBuiltPopup_Closed`, which the popup's own `Close` sends after the hide.

A forced Ruhr Valley in Lahore locked, closed, and unlocked with the same ID, with no click. Confirmed on Windows on 2026-11-15.

### With other cinematic popups up

The natural wonder popup and Gathering Storm's natural disaster popup set the `CINEMATIC` interface mode and hold the event queue, as the wonder built popup does. See [popups.md](popups.md).

A natural disaster popup held the AI turns. On turn 87, the player's turn stayed inactive for 4 minutes with it up, and turn 88 began 15 s after it was closed. Confirmed on Windows on 2026-11-13.

### The end turn action

`SentientSystems_EndTurn` sends the same request from `SentientSystemsCore_UI`. See [design/core/mod/actions/turn.md](../../design/core/mod/actions/turn.md).

On turn 53, with one unit that needed orders and no other blocker, the call without `force` returned that unit as the reason. With `force`, it ended the turn. A third call in the same turn was refused, and turn 54 began more than 15 s later. Confirmed on Windows on 2026-11-11.

On turn 54, the call without `force` named the great person and production blockers, with their choices, and 30 units that needed orders. The game also listed `ENDTURN_BLOCKING_UNITS`, which the reason leaves out. Confirmed on Windows on 2026-11-11.

On turn 85, the call with `force` returned `{"ok":true}` with Scythia's leader screen up, and the turn didn't end. The action had recorded the request, so it would refuse a second call in that turn. Confirmed on Windows on 2026-11-13.

The action now refuses while a session is open. On turn 97, with Vietnam's promise up, the call with `force` named Vietnam and sent no request. After `SentientSystems_RespondToSession` answered the promise, the call with `force` ended the turn.

During the AI turns that followed, a Cree deal held the turn. Confirmed on Windows on 2026-11-13.

A forced end skips every blocker and every unit that needs orders, and its result lists them. With `actionsPerTurn` set to `1`, the bridge forced the end of turn 1 after a `unit_action` that founded a city, and the result listed units 65536 and 131073 and no other blocker.

On turn 2, after a `set_research`, it listed `ENDTURN_BLOCKING_PRODUCTION` and unit 131073. Both turns ended, and turn 3 began. Confirmed on Windows on 2026-11-27.

### With a queued move that stops short

Ending the turn runs the units' queued moves first. On turn 5 of a duel map, a warrior's queued move toward an ocean tile stopped short, and the unit needed orders again. The game cancelled the end, and `AGENT_TURN 0` printed 0.2 s after the request, with the turn still at 5.

The action had recorded the request, so it refused the next three calls as a turn already ended, and the player had to press **Next Turn**. Confirmed on Windows on 2026-11-19.

The turn signal now clears the request. From the turn 5 save, the same end started the turn again 0.27 s later. A move east for the warrior and a second call then ended the turn, and turn 6 began with gold up from 25 to 31. Confirmed on Windows on 2026-11-19.

`Events.PlayerTurnActivated` passes `isFirstTime` as false when it starts the cancelled turn again, and true for the next turn. The same replay printed `AGENT_TURN 0 again` 0.2 s after the end, then `AGENT_TURN 0` for turn 6.

A load fires the event with `isFirstTime` true. In `Lua.log`, the event printed `AGENT_TURN 0` right after `GAME_READY 4`, and the resync printed it again. The bridge got only the resync's line, because the event fired during the socket reset. Confirmed on Windows on 2026-11-19.

## Method

Run each step through the tuner, and record the Lua state you ran it in.

1. **End the turn.** Run `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`, and check that the next `AGENT_TURN` line arrives.
2. **Run the action.** With a blocker left, call `endTurn` from `packages/core/bridge/src/actions/turn.ts` without `force`, then with `force`, then with `force` again. Check the reason, the end of the turn, and the refusal.
3. **End the turn with a leader screen up.** Declare war on a major civ with `SentientSystems_DeclareWar`, then send the request. Read `Game.GetCurrentGameTurn()` and `Players[0]:IsTurnActive()` 10 s later.
4. **Act with the wonder built popup up.** Force a wonder to finish, so the popup opens. Send a move and `SentientSystems_EndTurn(0, true)`, and read the unit and the turn. Then release the lock's event ID from `Lua.log` with the steps of `Close`, and read them again.
5. **Force the end at a limit.** Set `actionsPerTurn` to `1` in the config file, and run the bridge on a new game. Check that each turn ends and the log names what it skipped.

## Results

The bridge ran this step in a single-player game, with one city and one unit.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `Game.GetCurrentGameTurn()`, `UI.CanEndTurn()`, and `GetFirstEndTurnBlocking` | `SentientSystemsCore_UI` | Turn 1, `true`, and `ENDTURN_BLOCKING_RESEARCH` | 2026-10-23 |
| `SentientSystems_EndTurn(0, false)`, then `(0, true)` twice, on turn 53 | `SentientSystemsCore_UI` | The unit that needed orders as the reason, then `{"ok":true}`, then "You already ended turn 53." Turn 54 began | 2026-11-11 |
| `SentientSystems_EndTurn(0, false)` on turn 54 | `SentientSystemsCore_UI` | The great person and production blockers and 30 units as the reason | 2026-11-11 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` | `SentientSystemsCore_UI` | The turn ended. `AGENT_TURN 0` came 3 s later, and the same three calls returned turn 2, `true`, and `ENDTURN_BLOCKING_RESEARCH` | 2026-10-23 |
| `SentientSystems_EndTurn(0, true)` on turn 85, with Scythia's comment up | `SentientSystemsCore_UI` | `{"ok":true}`. Scythia's session closed, and the turn stayed at 85 | 2026-11-13 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` with the Netherlands leader's goodbye up | `SentientSystemsCore_UI` | The screen closed, and the turn stayed at 85 | 2026-11-13 |
| The same request with only the map up | `SentientSystemsCore_UI` | The turn ended | 2026-11-13 |
| `SentientSystems_MoveUnit` and `SentientSystems_EndTurn(0, true)` on turn 56, with the wonder built popup up | `SentientSystemsCore_UI` | `{"ok":true}` for both. The unit didn't move, and the turn didn't end | 2026-11-14 |
| `UI.ReleaseEventID` with the lock's ID, and the other steps of `Close` | `SentientSystemsCore_UI` | The popup closed. The unit moved, and the AI turns ran | 2026-11-14 |
| `FinishProgress()` on Lahore, building `BUILDING_RUHR_VALLEY`, with the core mod's button press | `GameCore_Tuner` | A lock, `WonderBuiltPopup_Shown`, then `WonderBuiltPopup_Closed` and the unlock, the context hidden, and `SELECTION` | 2026-11-15 |
| `end_turn` on turn 5, with a warrior's queued move toward an ocean tile | `SentientSystemsCore_UI` | `{"ok":true}`, then `AGENT_TURN 0` 0.2 s later on turn 5. The next three calls failed with "You already ended turn 5." | 2026-11-19 |
| The same end from the turn 5 save with the fix, then `move_unit` and `end_turn` | `SentientSystemsCore_UI` | The turn started again 0.27 s later. The second call ended it, and turn 6 began | 2026-11-19 |
| A load of the turn 5 save, then the same end, `move_unit`, and `end_turn`, with the `isFirstTime` line | `SentientSystemsCore_UI` | In `Lua.log`, `AGENT_TURN 0` from the event and the resync after the load, `AGENT_TURN 0 again` after the first end, and `AGENT_TURN 0` for turn 6 | 2026-11-19 |
| The bridge's forced end at the actions per turn limit of 1, on turns 1 and 2 of a new game | `SentientSystemsCore_UI` | Turn 1 skipped units 65536 and 131073. Turn 2 skipped `ENDTURN_BLOCKING_PRODUCTION` and unit 131073. Both turns ended | 2026-11-27 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: the end turn on 2026-10-23, the end turn action on 2026-11-11, a leader screen on 2026-11-13, the wonder built popup on 2026-11-14, a queued move that stops short on 2026-11-19, and a forced end on 2026-11-27.
