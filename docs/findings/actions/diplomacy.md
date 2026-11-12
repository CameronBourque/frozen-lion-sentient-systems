# Diplomacy actions

Status: open. Accepting and rejecting a deal an AI proposes, and declaring a surprise war on a major civ and a city-state, are confirmed in a running game with Gathering Storm, by hand and through the actions, with the files sent through the tuner.

How to close the leader screen that a war leaves open is open.

The game calls that the deal and war actions wrap, with the Lua state they run in. How the state reads a proposed deal is in [state/diplomacy.md](../state/diplomacy.md#deal-screen).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. How can the core mod close the leader screen that a war leaves open, or keep it from opening for an agent player? No timing of `CloseSession` closes it, and the screen has no event that closes it from outside. See [the leader screen](#the-leader-screen).

## What we know now

### Answering a deal

`DiplomacyDealView.lua` and its Gathering Storm replacement answer a deal the same way. Confirmed in files.

- **Accept.** When the deal arrives, `OnDiplomacyIncomingDeal` copies it with `DealManager.CopyIncomingToOutgoingWorkingDeal(player, other)`. **Accept**, in `OnProposeOrAcceptDeal`, then sends `DealManager.SendWorkingDeal(DealProposalAction.ACCEPTED, player, other)`.

  Before a joint war or a third-party war, the screen asks the player to confirm the war.
- **Refuse.** For a deal an AI started, **Refuse**, in `OnRefuseDeal`, adds `DiplomacyManager.AddResponse(sessionID, player, "NEGATIVE")`. It sends `DealProposalAction.REJECTED_PERMANENT` when one of the player's items is unacceptable.

  When the turn timer runs out, it sends `DealProposalAction.REJECTED` and closes the session.
- **Session.** Neither button closes the session. `ExitConversationMode` in `DiplomacyActionView.lua` closes it with `DiplomacyManager.CloseSession(sessionID)` when the player leaves the leader screen.

In `SentientSystemsCore_UI`, the negative response alone left the session open, with the deal still waiting, and the AI turns didn't go on. `CloseSession` then removed the deal, and the leader screen closed.

The AI turns went on, and another player proposed a deal a few seconds later, on their own turn. Confirmed on Windows on 2026-11-11.

The copy, `ACCEPTED`, and `CloseSession`, sent together, made the deal. Open Borders from the other player was in place, `DealManager.GetPlayerDeals` went from 0 deals to 1, and no proposal was left. Confirmed on Windows on 2026-11-11.

### The deal action

`SentientSystems_RespondToDeal` sends the same calls from `SentientSystemsCore_UI`. See [design/core/mod/actions/deals.md](../../design/core/mod/actions/deals.md).

It rejected Qin's deal and accepted player 5's, and the leader screen closed after each. A second call for each player returned the reason for no deal waiting. Confirmed on Windows on 2026-11-11.

### Declaring war

`DeclareWar` in `DeclareWarPopup.lua` sends `DiplomacyManager.RequestSession(attacker, defender, "DECLARE_SURPRISE_WAR")` for a major civ.

For a city-state, it sends `UI.RequestPlayerOperation` with `PlayerOperations.DIPLOMACY_DECLARE_WAR`, and `PARAM_PLAYER_ONE` and `PARAM_PLAYER_TWO` set to the two players.

It tells them apart by `GetCivilizationLevelTypeID`. The formal war and the other casus belli are their own sessions, such as `DECLARE_FORMAL_WAR`. Confirmed in files.

- **The check.** The leader screen tests each option with `player:GetDiplomacy():IsDiplomaticActionValid(actionType, other, true)`, which returns whether it is allowed and a table whose `FailureReasons` are text keys.

  See `DiplomacySupport_RemoveInvalidSelections` in `DiplomacyStatementSupport.lua`. Confirmed in files.

  For `DIPLOACTION_DECLARE_SURPRISE_WAR`, it returned true for every met player at peace, city-states too, and false with no reasons for the 4 players already at war. Confirmed on Windows on 2026-11-11.
- **The session.** For a major civ, the session was open at once, and its `FromPlayer` was the player. Confirmed on Windows on 2026-11-11.

  With no other session open, closing the session right after the request kept the war. With another player's session open, the war session waited behind it, and closing it at once cancelled the war. Confirmed on Windows on 2026-11-11.
- **Other players' sessions.** After a war on player 4, Scythia opened a session of their own to comment, as their agenda reacts to the war. It held no deal. Confirmed on Windows on 2026-11-11.

### The leader screen

A war request plays the leader screen through: the other leader's reply, the leader scene, the reaction animation, and the goodbye. In `SentientSystemsCore_UI`, the reply statement and `Events.LeaderScreenFinishedLoading` came within a second of the request.

`Events.LeaderAnimationComplete` with `DECLARE_WAR_FROM_HUMAN` came 7 s to 9 s after it. Confirmed on Windows on 2026-11-12.

`OnDiplomacySessionClosed` in `DiplomacyActionView.lua` returns the screen to the overview of the other leader when the player started the session, and closes it only when the other player did. Before the screen is set up, it ignores the close. Confirmed in files.

No timing of `CloseSession` closed the screen. Closed at once, on the reply, or on the leader load, the screen ended on the overview. Closed on the animation, it ended on the goodbye. Confirmed on Windows on 2026-11-12.

The screen closes itself with `OnForceClose` when the local player's turn ends or begins, and when the wonder or natural wonder popup signals it opened. `InGame.lua` hides the whole HUD on those same popup signals. Confirmed in files.

`SentientSystems_DeclareWar` declared war on city-state 12 with no session, and on players 4 and 7 with the session closed at once. A second call for each returned the reason for a player already at war. Confirmed on Windows on 2026-11-11.

## Method

1. Load a save, and end the turn until an AI proposes a deal. Read `SentientSystems_GetProposalState(Players[0])`.
2. To reject, send `DiplomacyManager.AddResponse(sessionID, 0, "NEGATIVE")`, then `DiplomacyManager.CloseSession(sessionID)`, with the session from `DiplomacyManager.FindOpenSessionID(0, other)`. Read the proposals again.
3. To accept, send the copy and `SendWorkingDeal` with `ACCEPTED`, then `CloseSession`. Read `DealManager.GetPlayerDeals(0, other)` and the proposals.
4. To run the action before the `.modinfo` loads it, send `SentientSystemsCore_StateProposals.lua` and `SentientSystemsCore_ActionsDeals.lua` without their comment and include lines. Call `respondToDeal` from the bridge twice for each deal.
5. To declare war, call `declareWar` for a city-state and a major civ at peace, then again for each. Read `IsAtWarWith` and `FindOpenSessionID` for each player.
6. To test the session close, send `RequestSession` with `DECLARE_SURPRISE_WAR` and `CloseSession` in one call, with and without another session open, and read `IsAtWarWith` 3 s later.
7. To time the leader screen, add listeners in `SentientSystemsCore_UI` to `Events.DiplomacyStatement`, `Events.LeaderScreenFinishedLoading`, `Events.LeaderAnimationComplete`, and `Events.DiplomacySessionClosed` that log `os.clock()`. Close the war session from one of them, and look at the screen.

## Results

A single-player game with Gathering Storm, on turn 54, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| `AddResponse` with `NEGATIVE` on player 2's deal of Horses and a great work for a great work, Open Borders, and gold | The session stayed open, and the deal stayed in the proposals | 2026-11-11 |
| `CloseSession` on that session | Player 2's deal was gone, and the leader screen closed. Player 5 proposed Truffles for Open Borders and gold on their turn | 2026-11-11 |
| The copy, `SendWorkingDeal` with `ACCEPTED`, and `CloseSession` on player 5's deal | 1 deal with player 5, Open Borders from player 5, and no proposals left | 2026-11-11 |
| `respondToDeal(client, 0, 2, false)` after a reload, then again | `{"ok":true}`, and the leader screen closed. The second call returned the reason for no deal waiting | 2026-11-11 |
| `declareWar(client, 0, 12)` on a city-state, then again | At war within 3 s, with no session. The second call returned the already-at-war reason | 2026-11-11 |
| `declareWar(client, 0, 4)` before the action closed the session | At war, with the session open 3 s later and the Maori leader's reply on screen. Closing it closed the screen and kept the war. Scythia then opened a session to comment | 2026-11-11 |
| `RequestSession` and `CloseSession` in one call for player 6, with Scythia's session open | Not at war 3 s later | 2026-11-11 |
| The same for player 6, after closing Scythia's session | At war 3 s later, with no session open | 2026-11-11 |
| `declareWar(client, 0, 7)`, which closes the session itself, then again | At war, with no session open, and the leader screen on the overview. The second call returned the already-at-war reason | 2026-11-11 |
| A war on player 8, with the session closed by a listener on the reply statement | At war, and the leader screen on the overview | 2026-11-12 |
| A war on player 9, with the session closed on `LeaderScreenFinishedLoading` | At war, and the leader screen on the overview | 2026-11-12 |
| A war on player 11, with the session closed on `LeaderAnimationComplete`, 9 s after the request | At war. The animation played, and the leader screen ended on the goodbye | 2026-11-12 |
| `respondToDeal(client, 0, 5, true)`, then again | `{"ok":true}`, 1 deal with player 5 where there were 0, and the leader screen closed. The second call returned the reason for no deal waiting | 2026-11-11 |

Date checked: game files on 2026-11-11. Running game on Windows: the calls by hand and the action on 2026-11-11, and the leader screen on 2026-11-12.
