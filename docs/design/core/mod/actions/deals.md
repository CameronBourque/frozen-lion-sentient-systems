# Deal actions

How the core mod answers a deal another player proposes, as the deal screen does. Part of the [action API](README.md).

## Respond to a deal

`SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)` in `Scripts/Actions/SentientSystemsCore_ActionsDeals.lua` answers the deal that the other player has put to the player. See [diplomacy.md](../../../../findings/actions/diplomacy.md#answering-a-deal).

To accept, it copies the incoming deal to the outgoing one and sends it as `ACCEPTED`, as **Accept** does. To reject, it adds the `NEGATIVE` response, as **Refuse** does. Either way, it then closes the session, as the leader screen does when the player leaves it.

A deal is waiting when `SentientSystems_GetProposedDeal` returns one, the same check the state's `proposals` section makes. It is in `Scripts/State/SentientSystemsCore_StateProposals.lua`, which the action file loads.

Its reasons, in order, name no deal waiting from that player, and a deal that is no longer valid, which can only be rejected.

On the bridge, `respondToDeal` in `src/actions/deals.ts` sends the call.

## Decisions

| Decision | Reason |
| --- | --- |
| The action closes the session | Neither button closes it. While the session is open, the deal stays waiting and the AI turns don't go on |
| A refusal is always the `NEGATIVE` response | It is the screen's own refusal of an AI's deal. `REJECTED_PERMANENT`, for a deal with an unacceptable item, asks the AI to stop proposing it, which is a different choice |
| Accepting a war deal declares the war without a prompt | The screen's prompt asks the player to confirm. The agent confirms by accepting |
| The action answers the whole deal and can't change it | A counter-offer is proposing a deal, which is planned for phase 3 |
