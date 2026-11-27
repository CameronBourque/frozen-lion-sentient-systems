# What holds the end turn

Status: confirmed. A leader screen, the wonder built popup, and the other cinematic popups are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

What keeps an end turn request from ending the turn, or holds the AI turns after it. The request itself, and the core mod's end turn action, are in [end-turn.md](end-turn.md).

## Questions

None open. The project built and rock band popups are in [popups.md](popups.md#project-built-popup).

## What we know now

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

## Method

Run each step through the tuner, and record the Lua state you ran it in.

1. **End the turn with a leader screen up.** Declare war on a major civ with `SentientSystems_DeclareWar`, then send `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`. Read `Game.GetCurrentGameTurn()` and `Players[0]:IsTurnActive()` 10 s later.
2. **Act with the wonder built popup up.** Force a wonder to finish, so the popup opens. Send a move and `SentientSystems_EndTurn(0, true)`, and read the unit and the turn. Then release the lock's event ID from `Lua.log` with the steps of `Close`, and read them again.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_EndTurn(0, true)` on turn 85, with Scythia's comment up | `SentientSystemsCore_UI` | `{"ok":true}`. Scythia's session closed, and the turn stayed at 85 | 2026-11-13 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` with the Netherlands leader's goodbye up | `SentientSystemsCore_UI` | The screen closed, and the turn stayed at 85 | 2026-11-13 |
| The same request with only the map up | `SentientSystemsCore_UI` | The turn ended | 2026-11-13 |
| `SentientSystems_MoveUnit` and `SentientSystems_EndTurn(0, true)` on turn 56, with the wonder built popup up | `SentientSystemsCore_UI` | `{"ok":true}` for both. The unit didn't move, and the turn didn't end | 2026-11-14 |
| `UI.ReleaseEventID` with the lock's ID, and the other steps of `Close` | `SentientSystemsCore_UI` | The popup closed. The unit moved, and the AI turns ran | 2026-11-14 |
| `FinishProgress()` on Lahore, building `BUILDING_RUHR_VALLEY`, with the core mod's button press | `GameCore_Tuner` | A lock, `WonderBuiltPopup_Shown`, then `WonderBuiltPopup_Closed` and the unlock, the context hidden, and `SELECTION` | 2026-11-15 |

Date checked: game files on 2026-11-15. Running game on Windows: a leader screen and a natural disaster popup on 2026-11-13, the wonder built popup on 2026-11-14, and the Ruhr Valley close on 2026-11-15.
