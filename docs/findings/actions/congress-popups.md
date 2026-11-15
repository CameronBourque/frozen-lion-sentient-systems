# World Congress popups

Status: confirmed. The congress intro, the voting and results screen, and the emergency popup, and the core mod's close of each, are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

The screens a World Congress session opens, what each holds, and how the core mod closes each for an agent player. The vote action is in [world-congress.md](world-congress.md). Closing them is [popups for agent players](../../roadmap/phase-1/done/popups.md#popups-for-agent-players).

## Questions

None open.

## What we know now

### Intro

`DLC/Expansion2/UI/Additions/WorldCongressIntro.lua` opens when a session starts, and again on `Events.LoadScreenClose` in a congress turn segment. It queues itself with `UIManager:QueuePopup`, with `AlwaysVisibleInQueue`. Confirmed in files.

Its **Continue** dequeues it and fires `LuaEvents.WorldCongressIntro_ShowWorldCongress`, which opens the voting screen. Confirmed in files.

On turn 85, with the session's blocker up, `UIManager:DequeuePopup` on `/InGame/WorldCongressIntro` closed the intro, and the voting screen didn't open.

`SentientSystems_VoteInCongress` then voted and cleared `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION`, with no screen open. Confirmed on Windows on 2026-11-15.

The vote action now ends the turn after its submit, as the screen's **Submit** does. After it voted on turn 85, turn 86 began with no other call. Confirmed on Windows on 2026-11-15.

With the core mod's close, from a save before the session, ending turn 85 started the session. The player's turn became active again on turn 85, with the session's blocker up and no congress screen open. Confirmed on Windows on 2026-11-15.

### Voting and results screen

`WorldCongressPopup.lua` is both the voting screen and the results screen. `ShowPopup` queues it with `UIManager:QueuePopup` and pushes `InputContext.Popup`. Confirmed in files.

`ClosePopup` dequeues it, pops the input context, and plays `WC_Exit`. Outside a session, it also sends `PlayerOperations.WORLD_CONGRESS_LOOKED_AT_AVAILABLE` to clear a blocker. Confirmed in files.

`LuaEvents.DiplomacyActionView_HideCongress` runs `ClosePopup`. Only this screen listens to it, and `DiplomacyActionView_Expansion2.lua` fires it. Confirmed in files.

On turn 86, after the session, the `WORLD_CONGRESS_RESULTS` notification activated by itself and opened the results screen, with no congress blocker. `DiplomacyActionView_HideCongress` closed it, and the player could click and pan the map. Confirmed on Windows on 2026-11-15.

With the core mod's close, turn 86 began with no congress screen open, no congress blocker, and no `WORLD_CONGRESS_RESULTS` notification left. Confirmed on Windows on 2026-11-15.

### Between-turns screen

`WorldCongressBetweenTurns.lua` opens from `LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns`, which the voting screen fires after its own **Submit**. While its timer animation runs at the end of the turn, it holds the event with `UI.ReferenceCurrentEvent()`. Confirmed in files.

With the intro closed, the voting screen never opens, so this screen doesn't either. The turn 85 session ended with no lock from it. Confirmed on Windows on 2026-11-15.

### Emergency popup

`WorldCrisisPopup.lua` opens from `Events.EmergencyAvailable` and `LuaEvents.WorldCongress_ShowEmergency`, and queues itself with `UIManager:QueuePopup`. Confirmed in files.

Its `Close` sends `PlayerOperations.ACCEPT_EMERGENCY` when the emergency needs no answer, then slides out and dequeues when the slide ends. Only `LuaEvents.DiploScene_SceneOpened` runs it from outside. Confirmed in files.

It needs an answer only when the emergency hasn't begun: `inputRequired` in `WorldCrisisSupport.lua` is `not kEmergency.HasBegun`. Then it shows **Join** and **Reject**, which send `ACCEPT_EMERGENCY` or `REJECT_EMERGENCY`.

Otherwise it shows **OK**, and `Close` sends `ACCEPT_EMERGENCY` to say the player saw it. Confirmed in files.

On turn 55, a special session voted 55 votes for the Betrayal Emergency against player 10, through the vote action. Turn 56 began with the emergency popup open, the emergency begun, the player at war with player 10, and `NOTIFICATION_EMERGENCY_DECLARED`.

`UIManager:DequeuePopup` on `/InGame/WorldCrisisPopup` closed it, with the war and the notification unchanged. `ACCEPT_EMERGENCY` sent after changed neither. Confirmed on Windows on 2026-11-15.

The popup shows every row of `Emergencies_XP2`: the hostile ones, such as `EMERGENCY_BACKSTAB`, and the others, such as `EMERGENCY_SEND_AID` and the scored competitions like `EMERGENCY_WORLDS_FAIR`.

It also shows an emergency's result, with the gold, silver, and bronze tiers of a competition. Confirmed in files.

With the core mod's close, the same vote, with 23 votes, left turn 56 with the popup closed, the war on, and the notification up. Confirmed on Windows on 2026-11-15.

## Method

1. Load a save with the congress intro up, and send each step through the tuner to `SentientSystemsCore_UI`.
2. Call `UIManager:DequeuePopup` on `/InGame/WorldCongressIntro`, then `SentientSystems_VoteInCongress`, and read the blockers and which congress contexts are open.
3. End the turn, and read which congress contexts are open each 5 s.
4. Fire `LuaEvents.DiplomacyActionView_HideCongress`, and read the results screen's context, the interface mode, and the blockers.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `UIManager:DequeuePopup` on `/InGame/WorldCongressIntro`, on turn 85 | `SentientSystemsCore_UI` | The intro hidden and out of the queue, and the voting screen hidden | 2026-11-15 |
| `SentientSystems_VoteInCongress` with option A, the first target, and 1 vote on each resolution | `SentientSystemsCore_UI` | `{"ok":true}`. No blocker, and no congress screen open | 2026-11-15 |
| `SentientSystems_EndTurn(0, true)` | `SentientSystemsCore_UI` | Turn 86 began, with the results screen open from `WORLD_CONGRESS_RESULTS` | 2026-11-15 |
| `LuaEvents.DiplomacyActionView_HideCongress()` | `SentientSystemsCore_UI` | The screen hidden and out of the queue, `SELECTION`, and no congress blocker | 2026-11-15 |
| `SentientSystems_EndTurn(0, true)` on turn 85, before the session, with the core mod's close | `SentientSystemsCore_UI` | Turn 85 active again, with the session's blocker and no congress screen open | 2026-11-15 |
| `SentientSystems_VoteInCongress` as before, then `SentientSystems_EndTurn(0, true)` | `SentientSystemsCore_UI` | `{"ok":true}`, then "You already ended turn 85", since the vote action didn't end the turn yet | 2026-11-15 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` | `SentientSystemsCore_UI` | Turn 86, with no congress screen open, no congress blocker, and `SELECTION` | 2026-11-15 |
| `SentientSystems_VoteInCongress` as before, with the vote action's end turn, after the session began on turn 85 | `SentientSystemsCore_UI` | `{"ok":true}`. Turn 86 began with no other call, no congress screen open, and the session over | 2026-11-15 |
| `SentientSystems_EndTurn(0, false)` on turn 86 | `SentientSystemsCore_UI` | The great person and production blockers as the reason | 2026-11-15 |
| `SentientSystems_VoteInCongress` with 55 votes for the Betrayal Emergency, in a special session on turn 55 | `SentientSystemsCore_UI` | `{"ok":true}`. Turn 56 began with the emergency popup open and the emergency begun | 2026-11-15 |
| `UIManager:DequeuePopup` on `/InGame/WorldCrisisPopup`, then `ACCEPT_EMERGENCY` for player 10 and emergency 5 | `SentientSystemsCore_UI` | The popup closed. At war with player 10, and `EMERGENCY_DECLARED` up, before and after each | 2026-11-15 |
| The same vote with 23 votes, reloaded with the core mod's close | `SentientSystemsCore_UI` | Turn 56 began with the popup hidden and out of the queue. At war with player 10, and `EMERGENCY_DECLARED` up | 2026-11-15 |

Date checked: game files on 2026-11-15. Running game on Windows on 2026-11-15.
