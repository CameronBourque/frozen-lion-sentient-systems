# Action API: deals and end turn

Add the actions that answer a deal, declare war, and end the turn. Part of [phase 1](README.md).

## Tasks

1. **Deals.** Add `SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)`, which accepts or rejects a deal another player proposes. Read the calls from `DiplomacyDealView.lua` and its replacements. Add `respondToDeal` to `src/actions/deals.ts`. Commit: `feat(core): add the deal response action`.
2. **End turn.** Add `SentientSystems_EndTurn(playerID, force)`. Without `force`, it returns the blocker as the reason when one is left. With `force`, it sends the request anyway, as the phase 0 gate did, and the game skips the blockers. It sends one request at most per turn. See [ending the turn](../../findings/actions/end-turn.md#ending-the-turn). Add `endTurn` to `src/actions/turn.ts`. Commit: `feat(core): add the end turn action`.
3. **Declare war.** Add `SentientSystems_DeclareWar(playerID, otherPlayerID)`, which the unit actions need because an attack that would start a war returns that as its reason. Read the calls from `DeclareWarPopup.lua`: `DiplomacyManager.RequestSession` with `DECLARE_SURPRISE_WAR`, or `UI.RequestPlayerOperation` for a city-state. Return a reason when the players are already at war. Add `declareWar` to `src/actions/deals.ts`. Commit: `feat(core): add the declare war action`.

## Done when

In a running game, each action works once from the bridge. `endTurn` without `force` returns the blocker as its reason while one is left, `respondToDeal` returns a reason when no deal is waiting, and `declareWar` returns a reason for a player already at war.

## Record

- Each request function, its Lua state, and its result, in `findings/actions/end-turn.md`.
- The reasons, in [in-game-lua.md](../../design/core/in-game-lua.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
