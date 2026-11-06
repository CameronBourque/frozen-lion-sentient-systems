# Game trade routes

Status: confirmed. The `tradeRoutes` key of `SentientSystems_GetChoices`, the destinations of each idle trader in a city, is confirmed in a running game, with the file sent through the tuner.

Its yields match the game's own `GetYieldsForRoute` for every destination checked, and the open route chooser lists the same number of destinations in the same order. The trade route action isn't built yet.

The calls the trade route choice uses, as the route chooser lists them. The other choices are in the [choices index](README.md). See [design/core/mod/choices.md](../../design/core/mod/choices.md).

## Questions

None open.

## What we know now

### Route chooser

`Base/Assets/UI/Choosers/TradeRouteChooser.lua` draws the chooser, with helpers in `Base/Assets/UI/TradeSupport.lua`. No DLC replaces either. Confirmed in files.

- **Origin.** `Refresh` takes the selected unit and the city on its tile with `Cities.GetCityInPlot`, and closes with no city. A trader outside a city has no chooser.
- **Destinations.** `RefreshChooserPanel` walks the local player's cities first, then every other player's from `Game.GetPlayers()`, with no filter, so city-states and Free Cities are included. A city is listed when both checks pass:
  - `CheckTradeRoute`, which is `UnitManager.CanStartOperation(unit, UnitOperationTypes.MAKE_TRADE_ROUTE, nil, params)`, with `PARAM_X0` and `PARAM_Y0` set to the city's tile and `PARAM_X1` and `PARAM_Y1` to the unit's tile.
  - `Game.GetTradeManager():GetTradeRoutePath(originOwner, originID, cityOwner, cityID)` returns a path of at least one plot.
- **Each entry.** `AddCityToDestinationStack` shows the city's name, the plot distance from the origin with `Map.GetPlotDistance`, a trading post icon when `city:GetTrade():HasActiveTradingPost(originOwner)`,
  a city-state quest icon when `Game.GetQuestsManager():HasActiveQuestFromPlayer` finds `QUEST_SEND_TRADE_ROUTE`,
  and the yields of the route for the origin.
- **Yields.** `GetYieldsForRoute` in `TradeSupport.lua` adds, for each yield, the trade manager's `CalculateOriginYieldsFromPotentialRoute`, `CalculateOriginYieldsFromPath`, and `CalculateOriginYieldsFromModifiers`.

  A route between two players multiplies the total by the origin owner's `GetTrade():GetInternationalYieldModifier(yieldIndex)`.

  The destination's side uses the `Destination` calls and the destination owner's modifier.

  The chooser shows only the origin's side in the list, and both sides once a city is selected. It rounds to one decimal and skips yields of zero.
- **Religious pressure.** With a majority religion in the origin, `GetReligiousPressureForCity` asks `CalculateOriginReligiousPressureFromPotentialRoute` or the `Destination` one, with the religion's index. The chooser shows it when it is above zero.
- **Starting.** `RequestTradeRoute` checks `CanStartOperation` again and sends `UnitManager.RequestOperation` with the same parameters. The action step uses that.
- **Idle traders.** `GetIdleTradeUnits` in `TradeSupport.lua` calls a unit idle when it has `MakeTradeRoute` in `GameInfo.Units` and no city's `GetTrade():GetOutgoingRoutes()` has its ID as `TraderUnitID`.

### In a running game

- A trader that already has a route failed `CanStartOperation` for every city tried, with no reason in the second result. The choice leaves it out through the idle check.
- A city that already has a route from the same origin, and the origin itself, also failed it, as did many cities with an empty path.
- `GetTradeRoutePath` returned a path for every city that passed `CanStartOperation`.
- `CalculateDestinationYieldsFromPotentialRoute` returned zero for every yield of every destination tried, so the destination's side of a route showed only religious pressure.

## Method

1. To test a choices file that the `.modinfo` doesn't list yet, send its code without its comments, as in [production.md](production.md#method), step 4, then call
   `SentientSystems_GetTradeRouteChoices(Players[Game.GetLocalPlayer()])` in `SentientSystemsCore_UI` and print the result with `SentientSystems_EncodeJson`.
2. To get an idle trader, send `UnitManager.InitUnit(0, "UNIT_TRADER", x, y)` in `GameCore_Tuner` on one of the player's city tiles. A route needs a free slot: the player's `GetTrade():GetNumOutgoingRoutes()` must be below `GetOutgoingRouteCapacity()`.
3. To compare the yields with the game's own, `include("TradeSupport")` in `SentientSystemsCore_UI`, and check `GetYieldsForRoute(origin, destination, forDestination)` against the choice for each destination. Its `kYieldValues` is one-based, by yield index plus one.

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The player's trader that already had a route to Aduatuca | `CanStartOperation` returned `false` for every city tried, and the choice left it out |
| A new trader in Noviodunum | `true` for 24 of 88 cities: 10 of the player's own, 5 of player 1, and 9 more of other players. The player's own Aduatuca and Bagacum, which already had a route from Noviodunum, and Noviodunum itself, returned `false` |
| The choice for that trader | One entry with 24 destinations in the player's cities first, each with its distance, trading post, path bonus, and the yields of both ends. Own cities gave the origin food, production, gold, and faith, and the destination only religious pressure. 8,278 bytes |
| The yields against `GetYieldsForRoute` | Equal for both ends of all 24 destinations, 48 comparisons, with the pressure |
| The open chooser for the same trader, as screenshots | 24 destinations, the player's own 10 first, then 14 of other players. Own cities show food, production, gold, and faith, and some show a religious pressure of 0.5. Others show gold, science, and faith |

Date checked: game files on 2026-11-05. Running game on Windows on 2026-11-05.
