# Diplomacy actions

Status: confirmed. Accepting and rejecting a deal an AI proposes are confirmed in a running game with Gathering Storm, by hand and through `SentientSystems_RespondToDeal`, with the files sent through the tuner.

The game calls that the deal actions wrap, with the Lua state they run in. How the state reads a proposed deal is in [state/diplomacy.md](../state/diplomacy.md#deal-screen).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

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

## Method

1. Load a save, and end the turn until an AI proposes a deal. Read `SentientSystems_GetProposalState(Players[0])`.
2. To reject, send `DiplomacyManager.AddResponse(sessionID, 0, "NEGATIVE")`, then `DiplomacyManager.CloseSession(sessionID)`, with the session from `DiplomacyManager.FindOpenSessionID(0, other)`. Read the proposals again.
3. To accept, send the copy and `SendWorkingDeal` with `ACCEPTED`, then `CloseSession`. Read `DealManager.GetPlayerDeals(0, other)` and the proposals.
4. To run the action before the `.modinfo` loads it, send `SentientSystemsCore_StateProposals.lua` and `SentientSystemsCore_ActionsDeals.lua` without their comment and include lines. Call `respondToDeal` from the bridge twice for each deal.

## Results

A single-player game with Gathering Storm, on turn 54, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| `AddResponse` with `NEGATIVE` on player 2's deal of Horses and a great work for a great work, Open Borders, and gold | The session stayed open, and the deal stayed in the proposals | 2026-11-11 |
| `CloseSession` on that session | Player 2's deal was gone, and the leader screen closed. Player 5 proposed Truffles for Open Borders and gold on their turn | 2026-11-11 |
| The copy, `SendWorkingDeal` with `ACCEPTED`, and `CloseSession` on player 5's deal | 1 deal with player 5, Open Borders from player 5, and no proposals left | 2026-11-11 |
| `respondToDeal(client, 0, 2, false)` after a reload, then again | `{"ok":true}`, and the leader screen closed. The second call returned the reason for no deal waiting | 2026-11-11 |
| `respondToDeal(client, 0, 5, true)`, then again | `{"ok":true}`, 1 deal with player 5 where there were 0, and the leader screen closed. The second call returned the reason for no deal waiting | 2026-11-11 |

Date checked: game files on 2026-11-11. Running game on Windows: the calls by hand and the action on 2026-11-11.
