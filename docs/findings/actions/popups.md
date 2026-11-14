# Popups

Status: open. The natural wonder popup is confirmed in a running game with Gathering Storm, with calls sent through the tuner. The wonder built popup is in [end-turn.md](end-turn.md#with-the-wonder-built-popup-up).

The popups that wait for a click, what each holds, and the steps that close each one from `SentientSystemsCore_UI`. Closing them for an agent player is [popups for agent players](../../roadmap/phase-1/agent-popups.md).

## Questions

1. Does the core mod's close work for the natural wonder popup from its `NaturalWonderPopup_Shown` event, as it does for the wonder built popup?

## What we know now

### Natural wonder popup

`Base/Assets/UI/Popups/NaturalWonderPopup.lua` opens from `Events.NaturalWonderRevealed` when a human local player first sees a natural wonder, in single player only. It isn't an end-turn blocker. Confirmed in files.

It locks with `ExclusivePopupManager:Lock`, as the wonder built popup does, so it holds the engine's event queue, and fires `LuaEvents.NaturalWonderPopup_Shown` right after. A second wonder found while it's up waits in its queue. Confirmed in files.

Its `Close` clears the plots it revealed with `UI.ClearTemporaryPlotVisibility("NaturalWonder")`, plays `Stop_Speech_NaturalWonders`, and calls `Events.StopAllCameraAnimations()`.

Then it fires `LuaEvents.NaturalWonderPopup_Closed`, sets the `SELECTION` interface mode, restores the lens, and unlocks. Confirmed in files.

`OnLocalPlayerTurnEnd` closes it when the player's turn ends, as the natural disaster popup does. Confirmed in files.

On turn 15, the popup opened during the AI turns, after the player's turn had ended, and held the start of the next turn. The player's turn stayed inactive for at least 20 s, with no `AGENT_TURN` line.

Releasing its event ID from `SentientSystemsCore_UI`, with the other steps of its `Close`, closed it. The interface came back, the mode went back to `SELECTION`, and the turn started with `AGENT_TURN 0`. Confirmed on Windows on 2026-11-14.

## Method

1. Send each step through the tuner to `SentientSystemsCore_UI`.
2. With the popup up, read `Game.GetCurrentGameTurn()` and `Players[0]:IsTurnActive()`, wait 20 s, and read them again.
3. Read the lock's event ID from the `PopupManager.LOCK` line in `Lua.log`. Run the steps of `Close`, with `UIManager:DequeuePopup` on `/InGame/NaturalWonderPopup`, `Input.PopContext()`, and `UI.ReleaseEventID` with that ID in place of the unlock.
4. Read the turn, the interface mode, and whether the popup's context is hidden 20 s later.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| The turn, twice 20 s apart, with the natural wonder popup up on turn 15 | `SentientSystemsCore_UI` | Turn 15, and the player's turn inactive both times | 2026-11-14 |
| The steps of `Close`, with `UI.ReleaseEventID(81032)` | `SentientSystemsCore_UI` | The popup's context hidden, the `SELECTION` mode, and the turn active. `AGENT_TURN 0` printed, and the interface's hide count went back to 0 | 2026-11-14 |

Date checked: game files on 2026-11-14. Running game on Windows on 2026-11-14.
