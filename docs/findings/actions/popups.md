# Popups

Status: confirmed. The natural wonder, natural disaster, project built, and rock band popups are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

So is the core mod's close of each. The wonder built popup is in [end-turn.md](end-turn.md#with-the-wonder-built-popup-up).

The popups that lock the engine's event queue and wait for a click, and the steps that close each one from `SentientSystemsCore_UI`. Closing them for an agent player is [popups for agent players](../../roadmap/phase-1/agent-popups.md). The popups that hold nothing are in [plain-popups.md](plain-popups.md).

## Questions

None open.

## What we know now

### Natural wonder popup

`Base/Assets/UI/Popups/NaturalWonderPopup.lua` opens from `Events.NaturalWonderRevealed` when a human local player first sees a natural wonder, in single player only. It isn't an end-turn blocker. Confirmed in files.

It locks with `ExclusivePopupManager:Lock`, as the wonder built popup does, so it holds the engine's event queue, and fires `LuaEvents.NaturalWonderPopup_Shown` right after. A second wonder found while it's up waits in its queue. Confirmed in files.

Its `Close` clears the plots it revealed with `UI.ClearTemporaryPlotVisibility("NaturalWonder")`, plays `Stop_Speech_NaturalWonders`, and calls `Events.StopAllCameraAnimations()`.

Then it fires `LuaEvents.NaturalWonderPopup_Closed`, sets the `SELECTION` interface mode, restores the lens, and unlocks. Confirmed in files.

`OnLocalPlayerTurnEnd` closes it when the player's turn ends, as the natural disaster popup does. Confirmed in files.

On turn 15, the popup opened during the AI turns, after the player's turn had ended, and held the start of the next turn. The player's turn stayed inactive for at least 20 s, with no `AGENT_TURN` line.

Releasing its event ID from `SentientSystemsCore_UI`, with the other steps of its `Close`, closed it. The interface came back, the mode went back to `SELECTION`, and the turn started with `AGENT_TURN 0`. Confirmed on Windows on 2026-11-14.

The core mod closes it by pressing its `Close` button when the batch of game events ends. On turn 15 the Great Barrier Reef's popup locked, closed, and unlocked with no click. Confirmed on Windows on 2026-11-15.

The camera stayed stuck, both with `Close` and with an earlier copy of its steps. `ShowPopup` calls `UI.OnNaturalWonderRevealed` before the lock, and the camera's fly-around around the wonder starts later and keeps the camera until it stops.

`Events.StopAllCameraAnimations()` in the close, and again on the next `GameCoreEventPublishComplete`, came too early. Sent through the tuner later, the same call freed it. Confirmed on Windows on 2026-11-15.

After the lock, `GameCoreEventPublishComplete` and `UIIdle` fired at once. About 1 s later came `LocalPlayerTurnBegin`, `PlayerTurnActivated`, and `GameCoreEventPlaybackComplete`. `SystemUpdateUI` didn't fire for `SentientSystemsCore_UI`.

Stopping the camera on that `GameCoreEventPlaybackComplete` freed it, after the button press too. Confirmed on Windows on 2026-11-15.

### Natural disaster popup

`DLC/Expansion2/UI/Additions/NaturalDisasterPopup.lua` locks with `ExclusivePopupManager:Lock` and fires `LuaEvents.NaturalDisasterPopup_Shown`, as the wonder built popup does. `ShowRandomEvent` checks only that the local player is human, not where the disaster is. Confirmed in files.

A meteor shower or a comet strike has the `SCENE_EVENT_TRIGGER` sequence type in `RandomEvent_Presentation`. Its popup opens on `Events.RandomEventStarted`, and on `Events.RandomEventOccurred` takes a second lock with `AcquireSequenceLock`.

`AcquireSequenceLock` releases the first lock's ID once more, then references the current event. Confirmed in files.

The core mod closes it by pressing its `Close` button when the batch of game events ends. On turn 15, `GameRandomEvents.ApplyEvent` from `GameCore_Tuner` raised a dust storm, a meteor shower, and a comet near Lahore. Each popup locked, closed, and unlocked with the same ID, and a unit moved at once.

So a meteor shower's or a comet's popup closes before `RandomEventOccurred`, and takes no second lock. The comet struck in the same turn as the meteor shower and showed as usual. Turn 16 began after the end turn. Confirmed on Windows on 2026-11-15.

A forest fire on a forest next to Lahore raised no popup.

### Project built popup

`ProjectBuiltPopup.lua` opens on `Events.CityProjectCompletedNarrative` for a project of the local player's with a `PopupText`, such as a space race launch, outside multiplayer.

It locks with `ExclusivePopupManager:Lock`, sets the `CINEMATIC` mode, and fires `LuaEvents.ProjectBuiltPopup_Shown`.

A project that ends while it's up waits in its own list. Its `Close` button shows that one next, or fires `ProjectBuiltPopup_Closed`, sets `SELECTION`, and unlocks. Confirmed in files.

`FinishProgress()` on a city building the Earth satellite opened it, with a `PopupManager.LOCK` line, in the `CINEMATIC` mode. `DoLeftClick()` on `/InGame/ProjectBuiltPopup/Close` fired `ProjectBuiltPopup_Closed`, unlocked once, hid it, and set `SELECTION`. Confirmed on Windows on 2026-11-15.

### Rock band popups

In Gathering Storm, `RockBandMoviePopup.lua` opens on `Events.PostTourismBomb` for a concert of the local player's, outside multiplayer and hotseat. 

It holds the current event with `UI.ReferenceCurrentEvent()`, queues itself, sets the `CINEMATIC` mode, plays the concert's camera and animation, and fires `LuaEvents.RockBandMoviePopup_Shown`.

Its `Close` button releases the event, stops the camera and animation, fires `LuaEvents.RockBandMoviePopup_OpenRockBandPopup` with the owner, unit, result, and tourism, then `RockBandMoviePopup_Closed`, and sets `SELECTION`.

`Events.PostTourismBomb(ownerID, unitID, x, y, resultID, tourism)` gives the result as an index into `Unit_RockbandResults_XP2`. `UnitOperationTypes.TOURISM_BOMB` is nil, so a request needs the operation's hash from `GameInfo.UnitOperations`.

The core mod's `concert` order sends it, and started a concert on player 1's harbor. Confirmed on Windows on 2026-11-15.

`RockBandPopup.lua` opens from that event and queues itself. It shows the result's tier, tourism, albums sold, and whether the band levels up, gains a promotion, or breaks up. Its `Close` only dequeues it. Confirmed in files.

A concert on player 1's harbor fired `PostTourismBomb` with 1000 tourism and result 4, and the movie popup showed in the `CINEMATIC` mode.

`DoLeftClick()` on `/InGame/RockBandMoviePopup/Close` opened the result popup, Creative Differences, and set `SELECTION`. `UIManager:DequeuePopup` hid the result popup. The band was gone. Confirmed on Windows on 2026-11-15.

With the core mod's close, both popups closed as they opened, at the end of the batch that locked them, and the mode went back to `SELECTION`. The concert's result popup was filled, then dequeued. The camera moved after each. Confirmed on Windows on 2026-11-15.

## Method

1. Send each step through the tuner to `SentientSystemsCore_UI`.
2. With the popup up, read `Game.GetCurrentGameTurn()` and `Players[0]:IsTurnActive()`, wait 20 s, and read them again.
3. Read the lock's event ID from the `PopupManager.LOCK` line in `Lua.log`. Run the steps of `Close`, with `UIManager:DequeuePopup` on `/InGame/NaturalWonderPopup`, `Input.PopContext()`, and `UI.ReleaseEventID` with that ID in place of the unlock.
4. Read the turn, the interface mode, and whether the popup's context is hidden 20 s later.
5. **Meteor showers and comets.** With the core mod loaded, run `GameRandomEvents.ApplyEvent({ EventType = <index>, Location = <plot index> })` in `GameCore_Tuner`, as the game's `Debug/Random Events.ltp` does, on an empty land tile the player sees.
   Read the `PopupManager` lines in `Lua.log`, then move a unit.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| The turn, twice 20 s apart, with the natural wonder popup up on turn 15 | `SentientSystemsCore_UI` | Turn 15, and the player's turn inactive both times | 2026-11-14 |
| The steps of `Close`, with `UI.ReleaseEventID(81032)` | `SentientSystemsCore_UI` | The popup's context hidden, the `SELECTION` mode, and the turn active. `AGENT_TURN 0` printed, and the interface's hide count went back to 0 | 2026-11-14 |
| `SentientSystems_EndTurn(0, true)` on turn 15, reloaded with the core mod's close | `SentientSystemsCore_UI` | A lock, with ID 852786, then the interface hidden and shown again. The context hidden, `SELECTION`, and `AGENT_TURN 0`. The camera stuck in the fly-around | 2026-11-15 |
| The same, with the camera stopped again on `GameCoreEventPublishComplete` | `SentientSystemsCore_UI` | The camera stuck | 2026-11-15 |
| The same, with a listener that stops the camera on the next `GameCoreEventPlaybackComplete` | `SentientSystemsCore_UI` | The camera moved | 2026-11-15 |
| `SentientSystems_MoveUnit` of a modern armor to see the Great Barrier Reef, on turn 15, with the button press and no camera stop | `SentientSystemsCore_UI` | A lock, `NaturalWonderPopup_Shown`, then `NaturalWonderPopup_Closed` and the unlock, and `SELECTION`. The camera stuck | 2026-11-15 |
| The same after a reload, with the camera stop | `SentientSystemsCore_UI` | The same lock and close, and the camera moved | 2026-11-15 |
| `ApplyEvent` with a dust storm (13), a meteor shower (31), and a comet (43), on turn 15, with the button press | `GameCore_Tuner` | For each, a lock, then the unlock with the same ID, the context hidden, `SELECTION`, and a move ran | 2026-11-15 |
| `ApplyEvent` with `RANDOM_EVENT_FOREST_FIRE` (33) on a forest | `GameCore_Tuner` | No popup | 2026-11-15 |
| `FinishProgress()` on Ratumacos, building `PROJECT_LAUNCH_EARTH_SATELLITE`, on turn 85 | `GameCore_Tuner` | A lock, with ID 1418556, `ProjectBuiltPopup_Shown`, and `CINEMATIC` | 2026-11-15 |
| `DoLeftClick()` on `/InGame/ProjectBuiltPopup/Close` | `SentientSystemsCore_UI` | `ProjectBuiltPopup_Closed`, `PopupManager.Unlock` with ID 1418556, the context hidden, and `SELECTION` | 2026-11-15 |
| A concert started from the unit panel | The game | `PostTourismBomb` with 0, the band, 49, 24, 4, and 1000, then `RockBandMoviePopup_Shown`, and `CINEMATIC` | 2026-11-15 |
| `DoLeftClick()` on `/InGame/RockBandMoviePopup/Close` | `SentientSystemsCore_UI` | `RockBandMoviePopup_OpenRockBandPopup` with 0, the band, 4, and 1000, then `RockBandMoviePopup_Closed`, `SELECTION`, and the result popup queued | 2026-11-15 |
| `UIManager:DequeuePopup` on `/InGame/RockBandPopup` | `SentientSystemsCore_UI` | The result popup hidden, and the band gone | 2026-11-15 |
| `FinishProgress()` on Ratumacos again, with the core mod's close | `GameCore_Tuner` | A lock, `ProjectBuiltPopup_Shown`, then `ProjectBuiltPopup_Closed` and the unlock, the context hidden, and `SELECTION` | 2026-11-15 |
| `UnitManager.RequestOperation` on the band with the hash of `UNITOPERATION_TOURISM_BOMB`, with the core mod's close | `SentientSystemsCore_UI` | `RockBandMoviePopup_Shown`, the result popup opened, and `RockBandMoviePopup_Closed`. Both hidden, and `SELECTION` | 2026-11-15 |
| `SentientSystems_UnitAction(0, band, "concert")` on player 1's harbor | `SentientSystemsCore_UI` | `{"ok":true}`, the concert's event in the state, both popups closed, and the band gone | 2026-11-15 |
| The same on a fortified knight, a spy on a mission, and an awake jet fighter and trader | `SentientSystemsCore_UI` | "Wake it first", "busy with an order", and "This kind of unit can't perform a concert." | 2026-11-15 |

Date checked: game files on 2026-11-14 and 2026-11-15. Running game on Windows on 2026-11-14 and 2026-11-15.
