# Ending the turn

Status: open. Ending the turn, and the core mod's end turn action, are confirmed in a running game. How the end-turn blockers interact with it is open.

The game call the end turn action wraps, with the Lua state it runs in and where we found it. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).

## Questions

1. Do the other popups that set the `CINEMATIC` interface mode hold the event queue as the wonder built popup does?

   `NaturalWonderPopup.lua`, `ProjectBuiltPopup.lua`, `RockBandMoviePopup.lua`, and Gathering Storm's `NaturalDisasterPopup.lua` set it. Confirmed in files.

   The natural wonder popup holds it. See [popups.md](popups.md#natural-wonder-popup).

   A natural disaster popup held the AI turns. On turn 87, the player's turn stayed inactive for 4 minutes with it up, and turn 88 began 15 s after it was closed. Confirmed on Windows on 2026-11-13.

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

The core mod closes it for an agent player. See [design/core/mod/README.md](../../design/core/mod/README.md#popups). In a listener on `LuaEvents.WonderBuiltPopup_Shown`, which the popup fires right after its lock, `UI.ReferenceCurrentEvent()` returned the lock's ID, 50196. Confirmed on Windows on 2026-11-14.

`InGame.lua` hides the interface on the same `Shown` event, and shows it again on `WonderBuiltPopup_Closed`. Sent from the `Shown` listener, the closed signal came before the hide, and the interface stayed hidden.

Sent on the next `Events.GameCoreEventPublishComplete`, it came after, and the interface came back. `ContextPtr:RequestRefresh()` never ran its handler, because the core mod's context is hidden. Confirmed on Windows on 2026-11-14.

### The end turn action

`SentientSystems_EndTurn` sends the same request from `SentientSystemsCore_UI`. See [design/core/mod/actions/turn.md](../../design/core/mod/actions/turn.md).

On turn 53, with one unit that needed orders and no other blocker, the call without `force` returned that unit as the reason. With `force`, it ended the turn. A third call in the same turn was refused, and turn 54 began more than 15 s later. Confirmed on Windows on 2026-11-11.

On turn 54, the call without `force` named the great person and production blockers, with their choices, and 30 units that needed orders. The game also listed `ENDTURN_BLOCKING_UNITS`, which the reason leaves out. Confirmed on Windows on 2026-11-11.

On turn 85, the call with `force` returned `{"ok":true}` with Scythia's leader screen up, and the turn didn't end. The action had recorded the request, so it would refuse a second call in that turn. Confirmed on Windows on 2026-11-13.

The action now refuses while a session is open. On turn 97, with Vietnam's promise up, the call with `force` named Vietnam and sent no request. After `SentientSystems_RespondToSession` answered the promise, the call with `force` ended the turn.

During the AI turns that followed, a Cree deal held the turn. Confirmed on Windows on 2026-11-13.

## Method

Run each step through the tuner, and record the Lua state you ran it in.

1. **End the turn.** Run `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`, and check that the next `AGENT_TURN` line arrives.
2. **Run the action.** With a blocker left, call `endTurn` from `packages/core/bridge/src/actions/turn.ts` without `force`, then with `force`, then with `force` again. Check the reason, the end of the turn, and the refusal.
3. **End the turn with a leader screen up.** Declare war on a major civ with `SentientSystems_DeclareWar`, then send the request. Read `Game.GetCurrentGameTurn()` and `Players[0]:IsTurnActive()` 10 s later.
4. **Act with the wonder built popup up.** Force a wonder to finish, so the popup opens. Send a move and `SentientSystems_EndTurn(0, true)`, and read the unit and the turn. Then release the lock's event ID from `Lua.log` with the steps of `Close`, and read them again.

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
| The core mod's listener, after a reload and a forced wonder | `SentientSystemsCore_UI` | No popup showed. The interface hid and came back, and a move ran at once | 2026-11-14 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: the end turn on 2026-10-23, the end turn action on 2026-11-11, a leader screen on 2026-11-13, and the wonder built popup on 2026-11-14.
