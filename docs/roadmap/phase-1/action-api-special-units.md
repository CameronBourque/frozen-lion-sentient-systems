# Action API: special units

Add the orders of the units that have their own screens and choices: traders, great people, religious units, and spies. Each needs its choices read first, because the agent has to pick a target from a list, and each needs a game with the right unit in it, so each is its own task. Each adds its own Lua file under `Scripts/Actions/` and its own file in `src/actions/`. Part of [phase 1](README.md).

## Tasks

1. **Trade route choices.** Add the destinations a trader can reach to the choices, as the route chooser lists them, with each route's yields. Read the calls from `TradeRouteChooser.lua`. Commit: `feat(core): add trade route destinations to the choices`.
2. **Trade routes.** Add `SentientSystems_TradeRoute(playerID, unitID, cityID)`, which starts a route to a destination from the choices, and a plunder order for a military unit on an enemy route. Add `tradeRoute` to `src/actions/trade.ts`. Commit: `feat(core): add the trade route actions`.
3. **Great people.** Add `activate`, and the orders that give a great person's production to a district, a wonder, a project, or a building, and `harvest_wonder`. Read the commands from `UnitPanel.lua`, and return the unit's reason when the tile is wrong. Commit: `feat(core): add the great person actions`.
4. **Religious units.** Add the orders to spread a religion, found one with a great prophet, heal followers, and condemn a heretic. Read the operations from `UnitPanel.lua`, and use a game with a religion. Commit: `feat(core): add the religious unit actions`.
5. **Spy choices.** Add the missions a spy can start in a district to the choices, as the mission chooser lists them. Read the calls from `EspionageChooser.lua`. Commit: `feat(core): add spy missions to the choices`.
6. **Spy missions.** Add `SentientSystems_SpyMission(playerID, unitID, mission)` and the counterspy order. Add `spyMission` to `src/actions/spies.ts`. Commit: `feat(core): add the spy mission actions`.

## Done when

In a running game, each order works once from the bridge. It also returns a reason for one illegal case: a trade route to a city that isn't a destination, a great person on a tile it can't use, a religious order without charges, and a spy mission that isn't in the list.

## Record

- Each request function, its Lua state, and its result, in `findings/actions-unit-orders.md`, or in a findings file of its own for the trade route, the great person, or the spy calls, with a row in the [findings index](../../findings/README.md).
- The trade route and spy choices, in the choices schemas in `packages/core/bridge/src/choices/`, with a row in the key table of [in-game-lua.md](../../design/core/in-game-lua.md).
- The rows of each order, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
