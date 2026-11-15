# Plain popups

Status: confirmed. The hero discovered, Secret Society, and civic completed popups, and the core mod's close and switch, are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

The popups that take no lock, so hold nothing, but wait for a click and some keep the player from the pause menu, so from saving, until they close. Closing them for an agent player is [popups for agent players](../../roadmap/phase-1/agent-popups.md). The popups that lock are in [popups.md](popups.md).

## Questions

None open.

## What we know now

### Secret Society and hero popups

- `DLC/Ethiopia/UI/Additions/SecretSocietyPopup.lua` opens from the `SECRETSOCIETY_DISCOVERED` and `SECRETSOCIETY_JOINED` notifications, through `LuaEvents.NotificationPanel_SecretSocietyDiscovered` and `_Joined` from `NotificationPanel_Ethiopia.lua`.
- `DLC/Babylon/UI/Additions/HeroesPopup.lua`, in the Heroes and Legends mode, opens from the `HERO_DISCOVERED` notification, through `LuaEvents.NotificationPanel_HeroDiscovered` from `NotificationPanel_Babylon_Heroes.lua`.

Each queues itself with `UIManager:QueuePopup`, and its `Close` is only `UIManager:DequeuePopup(ContextPtr)`. Neither fires a `LuaEvents` of its own when it opens or closes. Confirmed in files.

Both opened by themselves on turn 15, the hero popup first and the Secret Society popup once it closed, with no click on the notifications. Confirmed on Windows on 2026-11-14.

With the hero popup up, `SentientSystems_EndTurn(0, true)` ended the turn, and turn 16 began with the popup still up.

With the Secret Society popup up, the same call ended turn 16. Player 5 then opened a session, and the player's turn became active again on turn 16. Confirmed on Windows on 2026-11-14.

`UIManager:DequeuePopup` on `/InGame/HeroesPopup`, then on `/InGame/SecretSocietyPopup`, from `SentientSystemsCore_UI` closed each, and `UIManager:IsInPopupQueue` returned `false`. Confirmed on Windows on 2026-11-14.

The core mod closes them when a batch of game events ends. On turn 25 of another save, a listener on `Events.GameCoreEventPublishComplete` closed an open hero popup after a unit's move.

Reloaded on turn 15 with the core mod's close, the hero and Secret Society notifications came again, and neither popup was open afterward. Confirmed on Windows on 2026-11-14.

A hero popup can be open as soon as a load ends, before any batch ends. On turn 25 of a reloaded save, the hero popup was up after the load. Confirmed on Windows on 2026-11-14.

### Historic moment popup

`DLC/Expansion2/UI/Additions/HistoricMoments.lua`, in Rise and Fall, is the timeline screen, and also opens by itself for a historic moment of interest level 3 or more. It opens from `Events.NotificationActivated` for the `NOTIFICATION_PRIDE_MOMENT_RECORDED` notification. Confirmed in files.

When `UI.CanShowPopup` is false, it holds the moment in its own queue and shows it on a later `Events.UIIdle`. Confirmed in files.

`Show` queues the context with `UIManager:QueuePopup` and fires `LuaEvents.HistoricMoments_Opened`. `Close` dequeues it, plays `UI_Screen_Close`, and fires `LuaEvents.HistoricMoments_Closed`. `LaunchBar.lua` listens to both to show the timeline button open or closed. Confirmed in files.

`Options.GetAppOption("Debug", "SuppressInfoPopups")` in `AppOptions.txt` turns these popups off, for every player. Confirmed in files.

On turns 50 and 51, `SetCivic` from `GameCore_Tuner` recorded moments of interest level 3, and their `NOTIFICATION_PRIDE_MOMENT_RECORDED` notifications came, but no popup opened by itself. Why is unknown. Confirmed on Windows on 2026-11-15.

On turn 51, a world wonder forced to complete in Lahore opened the popup by itself for its moment, and the core mod closed it.

It also closed the timeline opened from the launch bar, and the moment opened from its notification. `HistoricMoments_Closed` followed each `HistoricMoments_Opened`. Confirmed on Windows on 2026-11-15.

### Era popups

`DLC/Expansion2/UI/Additions/EraCompletePopup.lua` opens on `Events.LocalPlayerTurnBegin` on the first turn of a new era. In single player it locks with `ExclusivePopupManager:Lock`. It closes itself when its animation ends, so it waits for no click. Confirmed in files.

`EraReviewPopup.lua` opens from `LuaEvents.EraReviewPopup_Show`, which `NotificationPanel_Expansion1.lua` fires when the `COMMEMORATION_AVAILABLE` or `COMMEMORATION_WITHOUT_CHOICE` notification activates. It queues itself with `UIManager:QueuePopup`. Confirmed in files.

Its close only dequeues it. Its **Continue** dequeues it and fires `LuaEvents.EraReviewPopup_MakeDedication`, which opens `DedicationPopup.lua`. Nothing else opens the dedication popup. Confirmed in files.

On turn 119, ending the turn into a new era locked the new-era popup. It unlocked by itself after its animation, and the turn began with `AGENT_TURN 0`.

The `COMMEMORATION_WITHOUT_CHOICE` notification activated by itself, and the era review popup opened. `UIManager:DequeuePopup` on `/InGame/EraReviewPopup` closed it. Confirmed on Windows on 2026-11-15.

That age was golden with no dedication to pick, because the game had the Dramatic Ages mode on. See [choices/dedications.md](../choices/dedications.md#games-with-no-dedications). Reloaded and ended again with the core mod's close turned off, the review popup stayed open on turn 120.

`GetPlayerNumAllowedCommemorations(0)` was 0, and no commemoration blocker was up, the same before and after `UIManager:DequeuePopup` closed it. Confirmed on Windows on 2026-11-15.

### Great work popup

`Base/Assets/UI/GreatWorkShowcase.lua` shows each great work the local player creates, from `Events.GreatWorkCreated`, and each relic, from `LuaEvents.NotificationPanel_ShowRelicCreated`. It's also the gallery that the launch bar and the great works overview open. Confirmed in files.

It doesn't use the popup queue or a lock. `ShowScreen` calls `ContextPtr:SetHide(false)`, and `HideScreen` calls `ContextPtr:SetHide(true)` and plays `Stop_Great_Music`, `Stop_Speech_GreatWriting`, and `Stop_Great_Works_Gallery_Ambience`. Confirmed in files.

`GreatWorkShowcase_Babylon_Heroes.lua` and `GreatWorkShowcase_KublaiKhan_Vietnam_MODE.lua` replace it with the same context name. Confirmed in files.

With the core mod's close, a great artist's `activate` order created a great work, and `Events.GreatWorkCreated` fired. The screen was hidden right after. Confirmed on Windows on 2026-11-15.

`LuaEvents.GreatWorksOverview_ViewGreatWork` for that work, as the gallery sends it, showed the screen. The core mod hid it within 5 s. Confirmed on Windows on 2026-11-15.

### Tech, civic, and boost popups

`Base/Assets/UI/Popups/TechCivicCompletedPopup.lua` shows each tech and civic the local player completes, and `BoostUnlockedPopup.lua` shows each boost. Each queues itself with `UIManager:QueuePopup` and takes no lock, so it holds nothing. Confirmed in files.

Both stop adding popups after `LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups()`, until `LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups()`. `TutorialUIRoot.lua` fires them, in the tutorial only. The switch lives in each popup's own Lua state, so a load turns it back on. Confirmed in files.

Each popup adds an entry only from the notification panel's `LuaEvents`, such as `NotificationPanel_ShowTechDiscovered` and `NotificationPanel_ShowTechBoost`, so none opens before the load ends. Confirmed in files.

The completed popup fires `LuaEvents.TechCivicCompletedPopup_TechShown` and `_CivicShown` when the player closes each one. Only `TutorialLoader_Expansion2.lua` listens to them. Confirmed in files.

On turn 31, with the civic completed popup up, the switch and `UIManager:DequeuePopup` on `/InGame/TechCivicCompletedPopup` from `SentientSystemsCore_UI` closed it. `UIManager:IsInPopupQueue` returned `false`. Confirmed on Windows on 2026-11-14.

With the switch on, a civic boost and a civic completed later in the same session showed no popup. Confirmed on Windows on 2026-11-14.

## Method

1. Send each step through the tuner to `SentientSystemsCore_UI`.
2. **Secret Society and hero popups.** With the hero or Secret Society popup up, call `SentientSystems_EndTurn(0, true)`, and read the turn 15 s later. Then call `UIManager:DequeuePopup` on its context.
3. **Tech and civic popups.** With the civic completed popup up, fire `LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups()`, and call `UIManager:DequeuePopup` on its context.
4. **The core mod's switch.** After a load, run `TriggerBoost` and `SetTech` on `Players[0]:GetTechs()` in `GameCore_Tuner`, and read whether each popup's context is in the popup queue.
5. **Historic moments.** Add listeners that print on `LuaEvents.HistoricMoments_Opened` and `_Closed`. Force a world wonder to complete, then click the moment's notification and the timeline button, and read the popup queue.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_EndTurn(0, true)`, with the hero discovered popup up on turn 15 | `SentientSystemsCore_UI` | `{"ok":true}`. Turn 16 began, with the popup still up | 2026-11-14 |
| `UIManager:DequeuePopup` on `/InGame/HeroesPopup` | `SentientSystemsCore_UI` | The context hidden, and out of the popup queue | 2026-11-14 |
| `SentientSystems_EndTurn(0, true)`, with the Secret Society popup up on turn 16 | `SentientSystemsCore_UI` | `{"ok":true}` and `AGENT_TURN 0`. A session from player 5 opened, and turn 16 was active again | 2026-11-14 |
| `UIManager:DequeuePopup` on `/InGame/SecretSocietyPopup` | `SentientSystemsCore_UI` | The context hidden, and out of the popup queue | 2026-11-14 |
| `SentientSystems_EndTurn(0, true)` on turn 15 of the same save, reloaded with the core mod's close | `SentientSystemsCore_UI` | With the natural wonder popup closed by hand, the hero and Secret Society notifications came, and both popups stayed hidden and out of the queue | 2026-11-14 |
| `LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups()`, then `UIManager:DequeuePopup` on `/InGame/TechCivicCompletedPopup`, on turn 31 | `SentientSystemsCore_UI` | The context hidden, and out of the popup queue | 2026-11-14 |
| `TriggerBoost` for Mining and `SetTech` for Pottery on turn 25, after a load with the core mod's switch | `GameCore_Tuner` | A `NOTIFICATION_TECH_BOOST`, which opens its popup by itself, and two `NOTIFICATION_TECH_DISCOVERED`. Neither popup opened | 2026-11-14 |
| `SentientSystems_EndTurn(0, true)` on turn 119, the last turn of an era | `SentientSystemsCore_UI` | `EraCompletePopupXP2` locked, then unlocked after its animation. `AGENT_TURN 0`, and the era review popup up | 2026-11-15 |
| `UIManager:DequeuePopup` on `/InGame/EraReviewPopup` | `SentientSystemsCore_UI` | The context hidden, and out of the popup queue | 2026-11-15 |
| The same turn end again, with the core mod's close turned off, then `DequeuePopup` | `SentientSystemsCore_UI` | 0 dedications allowed, no commemoration blocker, and `COMMEMORATION_WITHOUT_CHOICE`, with the popup open and after the close | 2026-11-15 |
| `SentientSystems_UnitAction(0, <artist>, "activate")` on a theater square, with the core mod's close | `SentientSystemsCore_UI` | `{"ok":true}`, `GreatWorkCreated` for the work, and the screen hidden | 2026-11-15 |
| `LuaEvents.GreatWorksOverview_ViewGreatWork` for that work | `SentientSystemsCore_UI` | The screen shown, then hidden within 5 s | 2026-11-15 |
| `SetCivic` for Naval Tradition on turn 50, then for Exploration on turn 51, with the core mod's close | `GameCore_Tuner` | Moments of interest level 3 and their notifications, and no popup | 2026-11-15 |
| A world wonder forced to complete on turn 51, then the moment's notification and the timeline button clicked, with the core mod's close | Game, by hand | Each popup closed at once, with `HistoricMoments_Opened` then `_Closed` | 2026-11-15 |

Date checked: game files on 2026-11-14. Running game on Windows on 2026-11-14 and 2026-11-15.
