# Deal actions

How the core mod answers a deal another player proposes, as the deal screen does, declares war, as the war popup does, and proposes peace, as the leader screen does. Part of the [action API](README.md).

## Respond to a deal

`SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)` in `Scripts/Actions/SentientSystemsCore_ActionsDeals.lua` answers the deal that the other player has put to the player. See [diplomacy.md](../../../../findings/actions/diplomacy.md#answering-a-deal).

To accept, it copies the incoming deal to the outgoing one and sends it as `ACCEPTED`, as **Accept** does. To reject, it adds the `NEGATIVE` response, as **Refuse** does. Either way, it then closes the session, as the leader screen does when the player leaves it.

A deal is waiting when `SentientSystems_GetProposedDeal` returns one, the same check the state's `proposals` section makes. It is in `Scripts/State/SentientSystemsCore_StateProposals.lua`, which the action file loads.

Its reasons, in order, name no deal waiting from that player, and a deal that is no longer valid, which can only be rejected.

On the bridge, `respondToDeal` in `src/actions/deals.ts` sends the call.

## Declare war

`SentientSystems_DeclareWar(playerID, otherPlayerID)` in the same file declares a surprise war. See [declaring war](../../../../findings/actions/war-and-peace.md#declaring-war).

For a major civ, it asks for the `DECLARE_SURPRISE_WAR` session and closes it at once, which keeps the war. The leader screen stays open on the overview until the turn ends. The popups step closes it. For a city-state, it sends the `DIPLOMACY_DECLARE_WAR` player operation, which opens no session.

Its reasons, in order, name a player not met, a player already at war, the game's own reasons from `IsDiplomaticActionValid`, or its own when the game gives none, and another diplomacy session that is open, for a major civ.

On the bridge, `declareWar` in `src/actions/deals.ts` sends the call.

## Propose peace

`SentientSystems_ProposePeace(playerID, otherPlayerID)` in the same file proposes peace. See [proposing peace](../../../../findings/actions/war-and-peace.md#proposing-peace).

For a major civ, it sets the outgoing deal to the leader screen's peace item, asks for a `MAKE_DEAL` session, proposes the deal, and closes the session.

Validating the deal adds what the game puts in a peace, such as an occupied city ceded to the player. For a city-state, it sends the `DIPLOMACY_MAKE_PEACE` player operation.

Its reasons, in order, name a player not met, a player at peace, the game's own reasons for a major civ, or its own when the game gives none, its own for a city-state that `CanMakePeaceWith` refuses, and another diplomacy session that is open, for a major civ.

An AI answers after the call. On the bridge, `proposePeace` in `src/actions/deals.ts` sends the call, then reads `SentientSystems_GetPeaceResult` every 250 ms for up to 5 s. It returns ok once the war has ended, and the last result, a failure, when it hasn't.

## Decisions

| Decision | Reason |
| --- | --- |
| The action closes the session | Neither button closes it. While the session is open, the deal stays waiting and the AI turns don't go on |
| A refusal is always the `NEGATIVE` response | It is the screen's own refusal of an AI's deal. `REJECTED_PERMANENT`, for a deal with an unacceptable item, asks the AI to stop proposing it, which is a different choice |
| Accepting a war deal declares the war without a prompt | The screen's prompt asks the player to confirm. The agent confirms by accepting |
| The action answers the whole deal and can't change it | A counter-offer is proposing a deal, which is planned for phase 3 |
| Declaring war is always a surprise war | The formal war and the other casus belli need conditions the state doesn't show yet. They come with the other diplomacy actions in phase 3 |
| Peace is the game's own peace deal, with nothing added | It keeps the cities the player occupies, which the game cedes to the player. Asking for more is proposing a deal, which is planned for phase 3 |
| The bridge waits for an AI's answer to peace | The answer comes after the call, within a second. A result that waits tells the agent whether the war is over, so it doesn't plan the next move on a guess. An AI that answers after the wait shows in the state |
| The war and peace actions close their session at once, and refuse while another session is open | An open session holds up the AI turns. A session asked for behind an open one waits, and closing it then cancels it. A city-state's operation opens no session, so it skips the check |
