# Game trade routes in the state

Status: confirmed. The `trade` section of `SentientSystems_GetState`, the player's routes and the routes of others that end in the player's cities, is confirmed in a running game with Gathering Storm, with the files sent through the tuner. The state matches the Trade Overview.

The calls the trade routes in the state use, as the Trade Overview shows them. The destinations of an idle trader are in [choices/trade-routes.md](../choices/trade-routes.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### The screen

`Base/Assets/UI/TradeOverview.lua` draws the screen, and no DLC replaces it. Confirmed in files.

- **My Routes.** `ViewMyRoutes` walks the local player's cities and collects each `city:GetTrade():GetOutgoingRoutes()`. It lists the routes to the player's own cities first, then those to each other player.

  A header shows `GetNumOutgoingRoutes()` over `GetOutgoingRouteCapacity()`, which the state's player section has.

  Capacity left over shows a button per idle trader and one to build a trader. The trade route choice covers the idle traders.
- **Routes To My Cities.** `ViewRoutesToCities` walks every other player's cities, and keeps the outgoing routes whose `DestinationCityPlayer` is the local player. A route between two of the player's own cities is on My Routes only.
- **A route.** The game's route table has `OriginCityPlayer`, `OriginCityID`, `DestinationCityPlayer`, `DestinationCityID`, `TraderUnitPlayer`, `TraderUnitID`, and the yield tables `OriginYields` and `DestinationYields`, each a list of `YieldIndex` and `Amount`.

  It has no turns left, and the screen shows none, so a route stays until the trader dies or the route is cancelled.
- **Yields.** `AddRoute` shows `GetYieldsForRoute` from [choices/trade-routes.md](../choices/trade-routes.md#route-chooser) for the origin, or for the destination with the benefits button, and the religious pressure. The state gives both ends, from the same calls as the choice.

## Method

1. To read a state section that the `.modinfo` doesn't load yet, send the code as in [choices/production.md](../choices/production.md#method), step 4, and send `SentientSystemsCore_State.lua` again so it calls it. This section also needs `SentientSystemsCore_ChoicesTradeRoutes.lua`, which holds `SentientSystems_GetRouteEnd`.
2. To compare the yields, `include("TradeSupport")` in `SentientSystemsCore_UI`, and check `GetYieldsForRoute(origin, destination, forDestination)` against each route's two ends. Its `kYieldValues` is one-based, by yield index plus one.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The routes against the raw routes | 18 outgoing of 18, and 1 incoming of 1 |
| The yields against `GetYieldsForRoute` | No mismatch, for both ends of every route, rounded to one decimal as the screen shows them |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
