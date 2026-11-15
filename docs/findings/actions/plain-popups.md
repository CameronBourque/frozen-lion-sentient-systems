# Plain popups

Status: confirmed. The hero discovered, Secret Society, and civic completed popups, and the core mod's close and switch, are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

The popups that take no lock, so hold nothing, but keep the player from the pause menu, so from saving, until they close. Closing them for an agent player is [popups for agent players](../../roadmap/phase-1/agent-popups.md). The popups that lock are in [popups.md](popups.md).

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

Date checked: game files on 2026-11-14. Running game on Windows on 2026-11-14.
