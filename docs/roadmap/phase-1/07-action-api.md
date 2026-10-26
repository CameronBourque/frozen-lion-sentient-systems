# Step 7: Action API

Add the action API for units, city production, purchases, techs, civics, policies, deals, and end turn. Each action wraps the request function the game's own UI calls, and a failed action returns its reason. Part of [phase 1](README.md).

## Tasks

1. **Result format.** Add `Scripts/SentientSystemsCore_Actions.lua`, imported into the UI state. Each action returns JSON `{ ok, reason }`. The reason comes from the game's check where it gives one, and from the API's own message otherwise. Commit: `feat(core): add the action result format`.
2. **Move.** Add `SentientSystems_MoveUnit(playerID, unitID, x, y)` from the [move path](../../findings/game-api.md#moving-a-unit). Check the target against the [reachable tiles](../../findings/game-api.md#checking-a-move) and return a reason when it isn't one. For a multi-turn move, let the game's pathfinding plan the route. Commit: `feat(core): add the move action`.
3. **Unit actions.** Add `SentientSystems_UnitAction(playerID, unitID, action, x, y)` for fortify, sleep, skip, found city, build improvement, pillage, attack, promote, and delete. Read the calls from `UnitPanel.lua`. Commit: `feat(core): add unit actions`.
4. **Production.** Add `SentientSystems_SetProduction(playerID, cityID, item, x, y)`, with the tile for a district or a wonder. Read the call from `ProductionPanel.lua`. Commit: `feat(core): add the production action`.
5. **Purchases.** Add `SentientSystems_Purchase(playerID, cityID, item, yield)`, which buys a unit or a building with gold or faith. Read the call from the purchase tab in `ProductionPanel.lua`. Commit: `feat(core): add the purchase action`.
6. **Tile purchases.** Add `SentientSystems_PurchaseTile(playerID, cityID, x, y)`. Read the call from `Base/Assets/UI/WorldView/PlotInfo.lua`. Commit: `feat(core): add the tile purchase action`.
7. **Techs, civics, and policies.** Add `SentientSystems_SetResearch`, `SentientSystems_SetCivic`, and `SentientSystems_SetPolicies`. Read the calls from the screens in step 6. Commit: `feat(core): add research, civic, and policy actions`.
8. **Other blockers.** Add one action for each other blocker in `findings/game-state.md`. Commit: `feat(core): add actions for the other end-turn blockers`.
9. **Deals.** Add `SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)`, which accepts or rejects a deal another player proposes. Read the calls from `DiplomacyDealView.lua` and its replacements. Commit: `feat(core): add the deal response action`.
10. **End turn.** Add `SentientSystems_EndTurn(playerID, force)`. Without `force`, it returns the blocker as the reason when one is left. With `force`, it sends the request anyway, as the phase 0 gate did, and the game skips the blockers. It sends one request at most per turn. See [ending the turn](../../findings/game-api.md#ending-the-turn). Commit: `feat(core): add the end turn action`.
11. **Bridge.** Add `src/actions.ts`, with one typed function for each action and a test for each with a fake client. Commit: `feat(core): call the action API from the bridge`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a move into deep water or a tech that isn't available yet.

## Record

- Each request function, its Lua state, and its result, in [game-api.md](../../findings/game-api.md#results). If the file passes 150 lines, move the actions into a new finding, `findings/game-actions.md`.
- The result format and the reasons, in [in-game-lua.md](../../design/core/in-game-lua.md).
