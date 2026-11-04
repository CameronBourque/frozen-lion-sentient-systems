# Action API: deals and end turn

Add the actions that answer a deal and end the turn. Part of [phase 1](README.md).

## Tasks

1. **Deals.** Add `SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)`, which accepts or rejects a deal another player proposes. Read the calls from `DiplomacyDealView.lua` and its replacements. Add `respondToDeal` to `src/actions.ts`. Commit: `feat(core): add the deal response action`.
2. **End turn.** Add `SentientSystems_EndTurn(playerID, force)`. Without `force`, it returns the blocker as the reason when one is left. With `force`, it sends the request anyway, as the phase 0 gate did, and the game skips the blockers. It sends one request at most per turn. See [ending the turn](../../findings/game-api.md#ending-the-turn). Add `endTurn` to `src/actions.ts`. Commit: `feat(core): add the end turn action`.

## Done when

In a running game, each action works once from the bridge. `endTurn` without `force` returns the blocker as its reason while one is left, and `respondToDeal` returns a reason when no deal is waiting.

## Record

- Each request function, its Lua state, and its result, in `findings/game-actions.md`.
- The reasons, in [in-game-lua.md](../../design/core/in-game-lua.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
