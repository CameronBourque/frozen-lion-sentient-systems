# Popups

Status: open. The natural wonder and hero discovered popups are confirmed in a running game with Gathering Storm, with calls sent through the tuner. The wonder built popup is in [end-turn.md](end-turn.md#with-the-wonder-built-popup-up).

The popups that wait for a click, what each holds, and the steps that close each one from `SentientSystemsCore_UI`. Closing them for an agent player is [popups for agent players](../../roadmap/phase-1/agent-popups.md).

## Questions

1. Does the core mod's close work for the natural wonder popup from its `NaturalWonderPopup_Shown` event, as it does for the wonder built popup?
2. Does the hero discovered popup open with no click, when the notification arrives? It opens from the notification's activate handler. If only a click opens it, an agent player never sees it.

   It fires no event of its own when it opens, so which event can the core mod close it from?

## What we know now

### Natural wonder popup

`Base/Assets/UI/Popups/NaturalWonderPopup.lua` opens from `Events.NaturalWonderRevealed` when a human local player first sees a natural wonder, in single player only. It isn't an end-turn blocker. Confirmed in files.

It locks with `ExclusivePopupManager:Lock`, as the wonder built popup does, so it holds the engine's event queue, and fires `LuaEvents.NaturalWonderPopup_Shown` right after. A second wonder found while it's up waits in its queue. Confirmed in files.

Its `Close` clears the plots it revealed with `UI.ClearTemporaryPlotVisibility("NaturalWonder")`, plays `Stop_Speech_NaturalWonders`, and calls `Events.StopAllCameraAnimations()`.

Then it fires `LuaEvents.NaturalWonderPopup_Closed`, sets the `SELECTION` interface mode, restores the lens, and unlocks. Confirmed in files.

`OnLocalPlayerTurnEnd` closes it when the player's turn ends, as the natural disaster popup does. Confirmed in files.

On turn 15, the popup opened during the AI turns, after the player's turn had ended, and held the start of the next turn. The player's turn stayed inactive for at least 20 s, with no `AGENT_TURN` line.

Releasing its event ID from `SentientSystemsCore_UI`, with the other steps of its `Close`, closed it. The interface came back, the mode went back to `SELECTION`, and the turn started with `AGENT_TURN 0`. Confirmed on Windows on 2026-11-14.

### Hero discovered popup

`DLC/Babylon/UI/Additions/HeroesPopup.lua`, in the Heroes and Legends mode, opens for the local player when the `HERO_DISCOVERED` notification is activated, through `LuaEvents.NotificationPanel_HeroDiscovered` from `NotificationPanel_Babylon_Heroes.lua`. Confirmed in files.

It queues itself with `UIManager:QueuePopup` and takes no lock, so it holds nothing. Its `Close` is only `UIManager:DequeuePopup(ContextPtr)`. It fires no `LuaEvents` when it opens or closes. Confirmed in files.

On turn 15, with the popup up, `SentientSystems_EndTurn(0, true)` ended the turn, and turn 16 began with the popup still up. The player can't reach the pause menu, so can't save, until it closes. Confirmed on Windows on 2026-11-14.

`UIManager:DequeuePopup` on `/InGame/HeroesPopup` from `SentientSystemsCore_UI` closed it, and `UIManager:IsInPopupQueue` returned `false`. Confirmed on Windows on 2026-11-14.

## Method

1. Send each step through the tuner to `SentientSystemsCore_UI`.
2. With the popup up, read `Game.GetCurrentGameTurn()` and `Players[0]:IsTurnActive()`, wait 20 s, and read them again.
3. Read the lock's event ID from the `PopupManager.LOCK` line in `Lua.log`. Run the steps of `Close`, with `UIManager:DequeuePopup` on `/InGame/NaturalWonderPopup`, `Input.PopContext()`, and `UI.ReleaseEventID` with that ID in place of the unlock.
4. Read the turn, the interface mode, and whether the popup's context is hidden 20 s later.
5. **Hero discovered popup.** With it up, call `SentientSystems_EndTurn(0, true)`, and read the turn 15 s later. Then call `UIManager:DequeuePopup` on `/InGame/HeroesPopup`.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| The turn, twice 20 s apart, with the natural wonder popup up on turn 15 | `SentientSystemsCore_UI` | Turn 15, and the player's turn inactive both times | 2026-11-14 |
| The steps of `Close`, with `UI.ReleaseEventID(81032)` | `SentientSystemsCore_UI` | The popup's context hidden, the `SELECTION` mode, and the turn active. `AGENT_TURN 0` printed, and the interface's hide count went back to 0 | 2026-11-14 |

| `SentientSystems_EndTurn(0, true)`, with the hero discovered popup up on turn 15 | `SentientSystemsCore_UI` | `{"ok":true}`. Turn 16 began, with the popup still up | 2026-11-14 |
| `UIManager:DequeuePopup` on `/InGame/HeroesPopup` | `SentientSystemsCore_UI` | The context hidden, and out of the popup queue | 2026-11-14 |

Date checked: game files on 2026-11-14. Running game on Windows on 2026-11-14.
