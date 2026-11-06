# State: trade routes and espionage

Add the trade routes and the spies to the state, as the Trade Overview and Espionage screens show them. The state has only the route count today, and it can't see a spy that is traveling or captured. Part of [phase 1](README.md).

## Tasks

1. **Trade routes.** Add the player's routes to the state: the outgoing routes, with each one's origin, destination, trader, and yields, and the routes of other players that end in the player's cities.

   Read the calls from `Base/Assets/UI/TradeOverview.lua`, which has the **My Routes** and **Routes To My Cities** tabs. Commit: `feat(core): add the trade routes to the state`.
2. **Available routes.** Add `SentientSystems_GetCityRoutes(player, cityID)`, the **Available Routes** tab for one city, and the tourism bonus of a route to the trade section. The full tab is too large for the state. Commit: `feat(core): add the available trade routes`.
3. **Operatives.** Add every spy the player has: idle, on a mission with its operation, city, and turns left, traveling with its destination and turns left, and captured.

   Read the calls from the **Operatives** tab of `Base/Assets/UI/PartialScreens/EspionageOverview.lua`. A traveling spy comes from `GetDiplomacy():GetNumSpiesOffMap()`, and a captured one from each player's `GetNthCapturedSpy`. Commit: `feat(core): add the operatives to the state`.
4. **City activity and mission history.** Add the enemy spies in the player's cities, and the past missions with their outcomes and loot. Read the calls from the **City Activity** and **Mission History** tabs. Commit: `feat(core): add the espionage activity to the state`.

## Done when

In a running game, each section matches its screen tab: the routes of the first two tabs, the available routes of a city, the three kinds of spy, the enemy operatives in the player's cities, and the mission history.

## Record

- Each section's calls and results, in a findings file of its own in [findings/state/](../../findings/state/README.md), with a row in its index.
- Each section, in [design/core/mod/state.md](../../design/core/mod/state.md).
- The parts of each section, listed in the `## Parts of a state section` table in the [core README](../../../packages/core/README.md).
