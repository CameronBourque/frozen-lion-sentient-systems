# City, trade, and spy actions

How the core mod runs the actions on a city's production and purchases, trade routes, and spy missions. Part of the [action API](../README.md).

## Production

`SentientSystems_SetProduction(playerID, cityID, item, x, y, append)` in `Scripts/Actions/SentientSystemsCore_ActionsCities.lua` replaces what a city is producing.

The item is the `type` of an option of the `production` choice, such as `UNIT_BUILDER`. A unit is a standard unit, not a corps or an army.

Its reasons name a type that is no unit, building, district, wonder, or project, and an item the panel doesn't list for the city. An item the panel greys out gets the game's own reasons.

With `append` the item goes to the end of the city's queue in place of replacing the current item.

The action refuses a full queue, which the panel would answer by replacing the last item.

A district or a wonder also takes the tile, `x` and `y`, from the `tiles` of the [placement call](../choices.md#placement), unless the city has placed it already.

Its reasons for a tile name a missing tile, a tile that isn't a placement tile, and a tile to buy first. See [production.md](../../../../findings/actions/production.md).

## Purchases

`SentientSystems_Purchase(playerID, cityID, item, yield)` in the same file buys a unit or a building. The item is the `type` of an option of the `purchases` choice, and the yield is the key it is listed under, `gold` or `faith`. A unit is a standard unit, and a district isn't bought here.

Its reasons name a yield that is neither, a type the game doesn't know, and an item the choice doesn't list for the yield. The game's reasons come back for a greyed-out item, with the panel's text when the player can't afford it. See [purchases.md](../../../../findings/actions/purchases.md).

`SentientSystems_PurchaseTile(playerID, cityID, x, y)` buys one of the `tiles` of the `purchases` choice with gold. Its reasons name a tile off the map, a tile the city can't buy, and the lens's tooltip when the player's gold falls short.

## Trade routes

`SentientSystems_TradeRoute(playerID, unitID, ownerID, cityID)` in `Scripts/Actions/SentientSystemsCore_ActionsTrade.lua` starts a route from the city a trader stands in to a destination of the `tradeRoutes` choice. The city is named by its owner and its ID, as the choice lists it.

Its reasons name a unit that isn't a trader, a trader that already has a route, a trader outside a city, and a player with no free route slot. A city the game refuses, or one with no path, gets one reason that points at the choice. See [trade.md](../../../../findings/actions/trade.md).

`plunder` is a unit order with no parameters, in the stances file. It plunders the enemy trade route on the unit's tile with the game's own command, for a unit with strength that isn't an air unit.

The game gives no reasons for it, so the action checks, in order, that the unit has moves, that a trader of another player is on the tile in any layer, and that the player is at war with that trader's owner.

A trader at war is immune when it has the immunity ability. When none of these explains the refusal, the reason is the general one.

## Spies

`SentientSystems_SpyMission(playerID, unitID, mission, district)` and `SentientSystems_SpyTravel(playerID, unitID, ownerID, cityID)` are in `Scripts/Actions/SentientSystemsCore_ActionsSpies.lua`.

A mission is the type from the spy missions choice, and a counterspy mission also takes the district to guard.

Their reasons name a spy that isn't ready, a spy in no city, the missions the spy can start when it names another, and a city that isn't a destination.

The game's own reasons come back for a mission it lists as disabled. See [spies.md](../../../../findings/actions/spies.md).

## Decisions

| Decision | Reason |
| --- | --- |
| A production or purchase item must be the `type` of an option of its choice | An agent can only ask for what the panel offers, and a refusal for anything else says so |
| A queue that is full is refused when appending | The panel would replace the last item, and the agent asked to add |
| A trade route destination is named by its owner and ID, as the choice lists it | The agent copies a destination from the choice without translating it |
