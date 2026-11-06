# Trade route actions

Status: open. Starting a trade route and plundering one are confirmed in a running game with Gathering Storm, with the files sent through the tuner. The plunder removes the trader and pays gold.

The game calls the trade route action and the plunder order wrap, with the Lua state each runs in and the reasons their checks give. The destinations a trader can reach are in [choices/trade-routes.md](../choices/trade-routes.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other unit actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Starting a route

`RequestTradeRoute` in `TradeRouteChooser.lua` calls `UnitManager.CanStartOperation` and then `UnitManager.RequestOperation` with `UnitOperationTypes.MAKE_TRADE_ROUTE`, and `PARAM_X0` and `PARAM_Y0` for the destination's tile and `PARAM_X1` and `PARAM_Y1` for the trader's. Confirmed in files.

- The check gives no reasons, and refuses a busy trader, a city with no route from this origin, the origin itself, a city with no path, and a player with no free slot.
- The action tells those cases apart before the check where it can: a unit that isn't a trader, a trader with a route, a trader outside a city, and no free slot in `GetNumOutgoingRoutes` against `GetOutgoingRouteCapacity`. The rest is one answer, a city the trader can't reach.
- A city is named by its owner and its ID, as the choice lists it, since a city's ID repeats across players.
- `Players[<number that is no player>]` is an object, and its `GetCities()` returns nothing, so the action checks both.

### Plunder

`UnitCommandTypes.PLUNDER_TRADE_ROUTE` is a unit command, not an operation, with no parameters. `UnitCommands.xml` names it "Plunder Trade Route".

The text has two reasons for it, `LOC_UNITCOMMAND_PLUNDER_TRADE_ROUTE_REQUIRES_WAR_DECLARATION` and `LOC_UNITCOMMAND_PLUNDER_TRADE_ROUTE_BLOCKED_BY_IMMUNITY`. Confirmed in files.

- The loose check, `CanStartCommand(unit, command, true)`, fails on a tile with no enemy trade route as well, so the kind of unit comes from its row: strength, and not an air unit. This is how `pillage` does it.
- `UnitCommandResults.FAILURE_REASONS` was empty whenever the check refused, so the action's reason says what the tile needs.

## Method

1. To start a route, send the files' code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_TradeRoute(playerID, unitID, ownerID, cityID)` for a trader in a city. A trader needs a free slot.
2. To get an idle trader, send `UnitManager.InitUnit(0, "UNIT_TRADER", x, y)` in `GameCore_Tuner` on a city's tile. The slot count is in the player's `GetTrade()`.
3. To plunder, find the tile of an enemy trader: a route's `TraderUnitID` in `city:GetTrade():GetOutgoingRoutes()`, with `TraderUnitPlayer`, and `UnitManager.GetUnit(player, id)` for its position.

   The player must be at war with its owner. Send `UnitManager.InitUnit(0, "UNIT_KNIGHT", x, y)` there in `GameCore_Tuner`, then call `SentientSystems_UnitAction(0, <unit>, "plunder")`.

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`, at war with player 10:

| Check | Result |
| --- | --- |
| A trader in a city, to the first destination of the choice | `{"ok":true}`. The route showed in its city's outgoing routes with the trader's ID, and the player's count went from 18 to 19 of 19 |
| The same trader again | `{"ok":false,"reason":"The trader already has a route."}` |
| A second trader, with no slot left | `{"ok":false,"reason":"The player has no free trade route slot."}` |
| A city that is the origin, a city ID that doesn't exist, and a player number that is no player | The unreachable reason, `Player 0 has no city 99999.`, and `Player 40 has no city 1.`. The last raised a Lua error until the action checked for `GetCities()` returning nothing |
| A knight on the tile of an enemy trader | `CanStartCommand` returned `true` for the loose and the real check. `SentientSystems_UnitAction` returned `{"ok":true}`. A moment later the trader was gone, the knight had no moves, and the check returned `false`. Gold was paid, an amount not recorded |
| The enemy's route count after the plunder | Unchanged at once. It is expected to update on its owner's turn, as the trader's removal reaches the route then |
| Knights on tiles of the enemy's territory and of a city-state's, with no trader | `false` for the loose and the real check, with the plunder reason of the action |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
