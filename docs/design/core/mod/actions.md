# Core mod actions

How the core mod runs actions through the game's own request functions, and the reasons a failed action returns. Part of the [core mod](README.md).

## Action API

Each action wraps the request function the game's own UI calls, and the game checks legality. A failed action returns its reason. The reason comes from the game's check where it gives one, and from the API's own messages for common cases.

The game's UI Lua files ship as plain text and show which call each screen makes. See the [action findings](../../../findings/actions/move-unit.md).

### Results

Every action returns the same JSON, `{ "ok": true }` or `{ "ok": false, "reason": "<text>" }`, with no `reason` when it worked. `SentientSystems_RunAction(name, action)` in `Scripts/Actions/SentientSystemsCore_Actions.lua` builds it, and the UI script loads the file.

The action is a function that returns nothing when it worked and the reason as text when it failed. A Lua error in it comes back as a failure with the error's first line, so the bridge always reads a reason.

The bridge reads the result through the stash. `sendAction` in [actions.ts](../../../../packages/core/bridge/src/actions/actions.ts) turns a failure to reach the game, or a reply that isn't a result, into a failed result with that error as the reason. The shape is the schema in the same file.

### Moves

`SentientSystems_MoveUnit(playerID, unitID, x, y)` in `Scripts/Actions/SentientSystemsCore_ActionsUnits.lua`, which `Scripts/Actions/SentientSystemsCore_Actions.lua` loads, moves a unit by the game's own route.

It checks the unit, the tile, the unit's moves, the war check, and the route, in that order, and returns the first failure as its reason. It never attacks and never declares war. Its reason for an air unit names rebase, deploy, and attack.

### Unit orders

`SentientSystems_UnitAction(playerID, unitID, action, x, y, type)` in the same file runs the unit orders below. They are in `Scripts/Actions/SentientSystemsCore_ActionsUnitStances.lua`, `SentientSystemsCore_ActionsUnitTiles.lua`, and the files that each order names.

Each order file registers its orders with `SentientSystems_AddUnitAction` in `SentientSystemsCore_ActionsUnits.lua`.

### Stances

`SentientSystems_UnitAction` gives a unit a stance (`fortify`, `sleep`, `skip`, `alert`, `heal`), `wake`, `delete`, or `promote`, with the promotion in `type`. The game gives no reasons for these, so the reason says what the unit is doing and whether to wake it first.

### Attacks

`attack` (with `x` and `y`) picks a melee, ranged, or air attack as the UI does, never starts a war, and lists the targets when the tile isn't one.

A ship's attack on a land tile it can raid is a coastal raid, and a refusal lists the raid tiles with the targets in range.

`priority_target` takes `x` and `y`, and is in the attacks file. A priority target hits the support or civilian unit that a military unit escorts, and the game marks the tiles that have one.

`SentientSystems_CityAttack(playerID, cityID, x, y)` in `Scripts/Actions/SentientSystemsCore_ActionsCities.lua` orders a city's shot.

### Production

`SentientSystems_SetProduction(playerID, cityID, item, x, y, append)` in `Scripts/Actions/SentientSystemsCore_ActionsCities.lua` replaces what a city is producing.

The item is the `type` of an option of the `production` choice, such as `UNIT_BUILDER`. A unit is a standard unit, not a corps or an army.

Its reasons name a type that is no unit, building, district, wonder, or project, and an item the panel doesn't list for the city. An item the panel greys out gets the game's own reasons.

With `append` the item goes to the end of the city's queue in place of replacing the current item.

The action refuses a full queue, which the panel would answer by replacing the last item.

A district or a wonder also takes the tile, `x` and `y`, from the `tiles` of the [placement call](choices.md#placement), unless the city has placed it already.

Its reasons for a tile name a missing tile, a tile that isn't a placement tile, and a tile to buy first. See [production.md](../../../findings/actions/production.md).

### Purchases

`SentientSystems_Purchase(playerID, cityID, item, yield)` in the same file buys a unit or a building. The item is the `type` of an option of the `purchases` choice, and the yield is the key it is listed under, `gold` or `faith`. A unit is a standard unit, and a district isn't bought here.

Its reasons name a yield that is neither, a type the game doesn't know, and an item the choice doesn't list for the yield. The game's reasons come back for a greyed-out item, with the panel's text when the player can't afford it. See [purchases.md](../../../findings/actions/purchases.md).

`SentientSystems_PurchaseTile(playerID, cityID, x, y)` buys one of the `tiles` of the `purchases` choice with gold. Its reasons name a tile off the map, a tile the city can't buy, and the lens's tooltip when the player's gold falls short.

### Trade routes

`SentientSystems_TradeRoute(playerID, unitID, ownerID, cityID)` in `Scripts/Actions/SentientSystemsCore_ActionsTrade.lua` starts a route from the city a trader stands in to a destination of the `tradeRoutes` choice. The city is named by its owner and its ID, as the choice lists it.

Its reasons name a unit that isn't a trader, a trader that already has a route, a trader outside a city, and a player with no free route slot. A city the game refuses, or one with no path, gets one reason that points at the choice. See [trade.md](../../../findings/actions/trade.md).

`plunder` is a unit order with no parameters, in the stances file. It plunders the enemy trade route on the unit's tile with the game's own command, for a unit with strength that isn't an air unit.

The game gives no reasons for it, so the action checks, in order, that the unit has moves, that a trader of another player is on the tile in any layer, and that the player is at war with that trader's owner.

A trader at war is immune when it has the immunity ability. When none of these explains the refusal, the reason is the general one.

### Great people

`activate` and `harvest_wonder` are unit orders with no parameters, in `SentientSystemsCore_ActionsUnitGreatPeople.lua`. `activate` uses a great person's ability, which for a great engineer is its production for a wonder.

The game gives the reasons, such as the tile the person must stand on. See [great-people.md](../../../findings/actions/great-people.md).

### Spies

`SentientSystems_SpyMission(playerID, unitID, mission, district)` and `SentientSystems_SpyTravel(playerID, unitID, ownerID, cityID)` are in `Scripts/Actions/SentientSystemsCore_ActionsSpies.lua`.

A mission is the type from the spy missions choice, and a counterspy mission also takes the district to guard.

Their reasons name a spy that isn't ready, a spy in no city, the missions the spy can start when it names another, and a city that isn't a destination.

The game's own reasons come back for a mission it lists as disabled. See [spies.md](../../../findings/actions/spies.md).

### Religious units

`found_religion`, `spread_religion`, `remove_heresy`, `heal_followers`, and `condemn_heretic` are unit orders with no parameters, in `SentientSystemsCore_ActionsUnitReligion.lua`.

A prophet founds a religion on its Holy Site, and the religion's name and beliefs are chosen in the religion blocker's action.

The game's reasons come back, such as the district a prophet must stand on. See [religious-units.md](../../../findings/actions/religious-units.md).

### Orders on the unit's tile

`found_city`, `improve` (with the improvement in `type`), and `pillage` act on the unit's own tile. Their reasons name what is wrong with the unit or the tile, such as the city that is too close.

`pillage` takes the improvement or district first and the road when the game won't pillage the tile otherwise, so a tile with both takes two orders.

### Builder jobs

`build_road`, `remove_feature`, `harvest`, `repair`, and `remove_improvement` are the builder jobs, in `SentientSystemsCore_ActionsUnitJobs.lua`.

- `build_road` is for a Military Engineer and builds the best route the player has, so `type` is optional. A route that differs is refused with the one the game would build.
- `repair` fixes a pillaged improvement, and a pillaged route when the improvement is whole.

Their reasons come from the unit and the tile: the moves and build charges left, a missing feature or resource, a tech the player lacks, an improvement in the way, and a tile the player doesn't own.

A resource the player can't see yet is not named. The game's own reason, such as a drought for a repair, comes back as it is.

### Add production

`add_production` has an engineer or builder add production to the item a city builds, at the cost of a build charge, in `SentientSystemsCore_ActionsUnitProduction.lua`. It works from the city for a building, and from the tile of a district.

The game allows one of four commands, by the kind of item. A builder gets them only through some leaders and buildings.

The game gives no reasons, so the core mod says when the unit is not a builder, has no moves, is outside a city, or stands off the tile of the district. It also says when the city builds nothing the unit can help.

### Upgrade

`upgrade` requests the game's upgrade command, in `SentientSystemsCore_ActionsUnitUpgrade.lua`. The game's reasons name the gold, the resources, and the territory, and the core mod adds the cost of the upgrade.

The game upgrades a unit to the last unit of its chain, and one missing step blocks it. So the core mod names the unit in the chain that needs a tech or civic the player lacks.

It also says when the unit has no moves left or no upgrade, because the game gives no reason for them. A fortified unit can upgrade.

### Formations

`form_corps`, `form_army`, `enter_formation`, and `exit_formation` are in `SentientSystemsCore_ActionsUnitFormations.lua`. The first three name the other unit by its ID, and a request without it returns the units that can join.

The game gives no reasons, so the core mod says when the player lacks the civic, the unit is a civilian or has no moves, no unit is next to it, or a corps or an army can't be split.

### Air and transport

`rebase` and `deploy` are for air units, and `airlift` and `paradrop` for land units. They take `x` and `y`.

They are in `SentientSystemsCore_ActionsUnitAir.lua` and `SentientSystemsCore_ActionsUnitTransport.lua`. `SentientSystemsCore_ActionsUnitTileOrders.lua` runs them, and `priority_target` too.

The game lists the tiles each can go to, and a request for another tile returns the nearest ones that work.

The game gives no other reasons, so the core mod says when the unit is of the wrong kind, has no moves left, or has no tile to go to. One case is a paradrop from a tile that is not a city or an airstrip.

## Decisions

| Decision | Reason |
| --- | --- |
| An attack that would start a war returns a reason, and a separate action declares war | The UI asks for confirmation in a dialog that has no call to answer, and a surprise war is a decision on its own |
| A move never attacks or declares war | The UI turns one click into a move, an attack, or a war confirmation. An agent needs each as its own deliberate action, so a move that would attack or start a war returns a reason instead |
| Every failed action returns a reason | The agent can decide again instead of repeating a mistake |
