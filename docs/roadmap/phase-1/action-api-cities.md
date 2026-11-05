# Action API: cities

Add the actions for a city: production, district and wonder placement, purchases, and tile purchases. Part of [phase 1](README.md).

## Tasks

1. **Production.** Add `SentientSystems_SetProduction(playerID, cityID, item)` for units, buildings, and projects. Read the call from `ProductionPanel.lua`.

   Check the item against the city's choices, and return a reason when it isn't one. Add `setProduction` to `src/actions/cities.ts`. Commit: `feat(core): add the production action`.
2. **Districts and wonders.** Add the `x` and `y` of the tile to `SentientSystems_SetProduction`, for a district or a wonder. Check the tile against the [placement tiles](../../design/core/mod/choices.md#placement) from the choices. Commit: `feat(core): add district and wonder placement to the production action`.
3. **Purchases.** Add `SentientSystems_Purchase(playerID, cityID, item, yield)`, which buys a unit or a building with gold or faith. Read the call from the purchase tab in `ProductionPanel.lua`. Add `purchase` to `src/actions/cities.ts`. Commit: `feat(core): add the purchase action`.
4. **Tile purchases.** Add `SentientSystems_PurchaseTile(playerID, cityID, x, y)`. Read the call from `Base/Assets/UI/WorldView/PlotInfo.lua`. Add `purchaseTile` to `src/actions/cities.ts`. Commit: `feat(core): add the tile purchase action`.
5. **Production queue.** Read how `ProductionPanel.lua` adds an item to the end of a city's queue in place of replacing the current item. In a running game, queue three items in one city and end turns until all three are built. Check that the city builds them in order with no new request.

   If the queue works, add an `append` flag to `SentientSystems_SetProduction`. A [standing order](../../design/decision-support/standing-orders.md#orders) build list needs this result. Commit: `feat(core): add the production queue to the production action`, or `docs: record the production queue` if the queue does not hold the items.

## Done when

In a running game, each action works once from the bridge. It also returns a reason for one illegal case: an item that isn't in the city's choices, a district on a tile that isn't a placement tile, a purchase without enough gold, and a tile that can't be bought.

The production queue is recorded as working or not working.

## Record

- Each request function, its Lua state, and its result, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions.md](../../design/core/mod/actions.md).
- Whether the production queue holds a build list, in the production finding. Remove the production queue question from [standing-orders.md](../../design/decision-support/standing-orders.md#open-questions), and rewrite the sentence about it under `## Orders` to match the result.
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
