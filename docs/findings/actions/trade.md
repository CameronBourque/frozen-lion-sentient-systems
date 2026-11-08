# Trade route actions

Status: open. Starting a trade route and plundering one are confirmed in a running game with Gathering Storm, with the files sent through the tuner. The plunder removes the trader and pays gold. The plunder reasons, immunity among them, are confirmed the same way.

The game calls the trade route action and the plunder order wrap, with the Lua state each runs in and the reasons their checks give. The destinations a trader can reach are in [choices/trade-routes.md](../choices/trade-routes.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other unit actions are in the [actions index](README.md).

## Questions

1. Why does the check refuse an embarked knight on the tile of an enemy trader at sea, when a frigate on the same tile can plunder? The action gives its general reason for it.

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
- Immunity is the trader ability `ABILITY_ECONOMIC_GOLDEN_AGE_PLUNDER_IMMUNITY`, which the economic golden age dedication gives, `COMMEMORATION_ECONOMIC` in `Expansion1_Moments.xml`.

  In the UI state, a unit's `GetAbility()` has `GetAbilities()`, the indexes of its active abilities in `GameInfo.UnitAbilities`, and no `GetAbilityCount` or `HasAbility`.

  In `GameCore_Tuner` it has `GetAbilityCount` and `ChangeAbilityCount`. Confirmed in files and on Windows on 2026-11-07.
- The check refused every plunder on the turn the war was declared, and allowed it on the next. Confirmed on Windows on 2026-11-07.

## Method

1. To start a route, send the files' code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_TradeRoute(playerID, unitID, ownerID, cityID)` for a trader in a city. A trader needs a free slot.
2. To get an idle trader, send `UnitManager.InitUnit(0, "UNIT_TRADER", x, y)` in `GameCore_Tuner` on a city's tile. The slot count is in the player's `GetTrade()`.
3. To plunder, find the tile of an enemy trader: a route's `TraderUnitID` in `city:GetTrade():GetOutgoingRoutes()`, with `TraderUnitPlayer`, and `UnitManager.GetUnit(player, id)` for its position.

   The player must be at war with its owner. Send `UnitManager.InitUnit(0, "UNIT_KNIGHT", x, y)` there in `GameCore_Tuner`, then call `SentientSystems_UnitAction(0, <unit>, "plunder")`.
4. To check the plunder reasons, send `UnitManager.InitUnit(0, "UNIT_KNIGHT", x, y)` in `GameCore_Tuner` on a trader of a player at peace and on an empty tile, and `UnitManager.FinishMoves(unit)` for one with no moves.
5. To check immunity, in `GameCore_Tuner`, send `Players[0]:GetDiplomacy():DeclareWarOn(<player>, WarTypes.FORMAL_WAR, true)` and the trader's `GetAbility():ChangeAbilityCount("ABILITY_ECONOMIC_GOLDEN_AGE_PLUNDER_IMMUNITY", 1)`.

   End the turn, then plunder with a unit on its tile. A trader at sea needs a naval unit, such as `UNIT_FRIGATE`.

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

The plunder reasons, on the same save on turns 85 and 86, at war with player 1 from turn 85:

| Check | Result |
| --- | --- |
| A knight on a trader of a player at peace | `No trader on the tile is of a player at war with you.` |
| A knight with no moves on a trader | `The unit has no moves left.` |
| A knight on an empty tile | `No trader of another player is on the tile.` |
| `GetAbilities()` in the UI state, for a trader given the immunity | The index of `ABILITY_ECONOMIC_GOLDEN_AGE_PLUNDER_IMMUNITY`, and none for the other traders |
| Knights on the tiles of traders of player 1 on turn 85, immune or not | `false` for the check, so the war was too new |
| Embarked knights on two tiles of traders at sea on turn 86 | `false` for the check, with the general reason |
| Frigates on the same tiles on turn 86 | `{"ok":true}` for a lone trader. On a tile with an immune trader and another, the other was plundered |
| A second frigate on that tile, with only the immune trader left | `false` for the check, and `The trade route on the tile is immune to plunder.` |

Date checked: game files on 2026-11-06 and 2026-11-07. Running game on Windows on 2026-11-06 and 2026-11-07.
