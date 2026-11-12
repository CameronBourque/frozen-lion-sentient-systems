# Action API: deals and end turn

Add the actions that end the turn, answer a deal, declare war, and propose peace. Part of [phase 1](README.md).

## Tasks

1. **End turn.** Add `SentientSystems_EndTurn(playerID, force)`. Without `force`, it returns the blocker as the reason when one is left. With `force`, it sends the request anyway, as the phase 0 gate did, and the game skips the blockers.

   It sends one request at most per turn. See [ending the turn](../../findings/actions/end-turn.md#ending-the-turn). Add `endTurn` to `src/actions/turn.ts`. Commit: `feat(core): add the end turn action`.
2. **Deals.** Add `SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)`, which accepts or rejects a deal another player proposes.

   Read the calls from `DiplomacyDealView.lua` and its replacements. An AI may propose a deal right after the turn ends, so check whether a deal waits after `endTurn`. To test, end turns until an AI proposes one.

   Add `respondToDeal` to `src/actions/deals.ts`. Commit: `feat(core): add the deal response action`.
3. **Declare war.** Add `SentientSystems_DeclareWar(playerID, otherPlayerID)`, which the unit actions need because an attack that would start a war returns that as its reason.

   Read the calls from `DeclareWarPopup.lua`: `DiplomacyManager.RequestSession` with `DECLARE_SURPRISE_WAR`, or `UI.RequestPlayerOperation` for a city-state.

   Return a reason when the players are already at war. Add `declareWar` to `src/actions/deals.ts`. Commit: `feat(core): add the declare war action`.
4. **Propose peace.** Add `SentientSystems_ProposePeace(playerID, otherPlayerID)`, which proposes a deal with the Make Peace agreement. Without it, the agent can end a war only by accepting an AI's offer.

   Read the calls from `DiplomacyActionView.lua` and `DiplomacyDealView.lua`: the outgoing working deal, its Make Peace item, and the request that proposes it. For a city-state, read the call the city-state screen makes.

   Return a reason when the players are not at war, when the game doesn't allow peace yet, and when the other player rejects it. Add `proposePeace` to `src/actions/deals.ts`. Commit: `feat(core): add the propose peace action`.

## Done when

In a running game, each action works once from the bridge. `endTurn` without `force` returns the blocker as its reason while one is left, and `respondToDeal` returns a reason when no deal is waiting.

`declareWar` returns a reason for a player already at war. `proposePeace` returns a reason for a player at peace, and ends a war that the other player agrees to end.

## Record

- Each request function, its Lua state, and its result, in `findings/actions/end-turn.md` for the end turn, and in `docs/findings/actions/diplomacy.md*` for the deal, war, and peace actions.
- The reasons, in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
