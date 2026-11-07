# Core mod state

How the core mod builds one player's view of the game. Part of the [core mod](README.md).

## State serializer

It builds a view of one player's game from that player's own visibility data, never from what is on screen. A map reveal that changes only the view can then never leak hidden information to an agent.

A reveal that writes the player's visibility data, such as FireTuner's **Reveal All**, does leak it. See [findings/state/tile-visibility.md](../../../findings/state/tile-visibility.md#firetuners-map-reveal).

The view holds what a player sees on these screens, grouped by screen. The list below shows what it holds now, and the [roadmap](../../../roadmap/README.md) says when the rest comes:

- **The map.** Revealed tiles, the player's units, and the rival cities and units the player can see, with the religion and religious strength of a religious rival unit.

  Each unit has what it is doing, its attacks left, its builder charges, and its formation. A religious unit has its religion, its religious strength, and its spread and heal charges, and a great person its class, individual, and action charges.
- **The city panel, and the City Status tab of Reports.** Each city's yields, growth, housing, amenities, loyalty, defense, districts, production, growth rate status, war weariness, governor, and religion.

  A city's religion is its majority, the pressure it exerts, the religion it will convert to and when, and the followers and pressure of each religion present.
- **The Next Turn button.** What blocks the end of the turn.
- **The top bar.** The gold and faith balances, the science, culture, faith, gold, and tourism per turn, the trade route capacity, and, with Gathering Storm, diplomatic favor.
- **The Yields tab of Reports.** Income by source, building and unit upkeep, deal payments, and net income per turn.
- **The Resources tab of Reports.** Strategic and luxury resources, and, with Gathering Storm, strategic stockpiles.
- **The Gossip tab of Reports.** What the player has heard about met players.
- **The Era Progress panel.** The era, era score, current age, the thresholds for the next age, turns until the next era, and the active effects.
- **The Great People screen.** Each candidate's era and effect, each met player's recruit progress, points per turn, and the gold and faith patronage costs.
- **The City-States screen.** Envoy tokens, the bonuses of each kind of city-state, and each city-state's envoys, suzerain, suzerain bonus, resources, quests, and the players with envoys there.
- **The Governors panel.** The appointed governors, their cities, and their promotions.
- **The Religion screen.** The pantheon, the religion, and its followers.
- **The diplomacy screens.** War or peace with each met player, proposed deals, relationships, grievances, and agendas.
- **The Trade Overview.** The player's routes, with the yields of both ends, the routes of other players that end in the player's cities, and the tourism bonus of a route.

  Its Available Routes tab is too large for the state, so `SentientSystems_GetCityRoutes` returns it for one city on demand.
- **The Espionage screen.** The spy capacity, each spy of the player: idle, on a mission, traveling, or captured, the districts and Gain Sources boosts of the other majors' cities, the last 10 missions with their outcomes and loot, and the other players' spies the player holds.
- **Their own screens.** Great works and tourism, and climate and disasters.
- **World Rankings and the leader panel.** The scoreboard and victory progress, as World Rankings shows them. Each met player's score, military strength, and science, culture, gold, and faith per turn, as the leader panel at the top right shows them.

The scoreboard lists every player in the screen's order. A met player has their ID and the values the screen shows, and an unmet player has only their place, as the screen shows a `?` icon.

A feature that isn't in the ruleset, such as loyalty without the Rise and Fall expansion, is left out.

## Files

`SentientSystems_GetState(playerID)` in `Scripts/State/SentientSystemsCore_State.lua` returns the view as JSON, and the UI script loads it with `include`. The bridge reads it through the stash.

Each section of the view has its own file in `Scripts/State/`, such as `SentientSystemsCore_StateCities.lua`, which defines one global, such as `SentientSystems_GetCityStates(player)`. The state file loads each one and puts the sections together.

The shape of each section is in the schemas in [packages/core/bridge/src/state/](../../../../packages/core/bridge/src/state/).

## Decisions

| Decision | Reason |
| --- | --- |
| State comes from the player's visibility data, not the screen | A map reveal that changes only the view can never leak to an agent |
| Tile contents come from the live plot, as the tooltip shows them | A player learns a tile's contents by hovering over it. The map's resource icons come from the `RESOURCES` layer, which is empty on tiles revealed without being seen, such as near a rival's city. The tooltip still shows them |
| The state includes the scoreboard and victory progress | A human sees it, and sweat levels measure against it |
| Find the state size by measurement | No useful budget exists before the first full game |
| Available routes are a function of one city, not a state section | The tab lists every origin and destination pair, 305 routes and 119 KB in one game, and one city is at most 8 KB. The choice lists only the cities where an idle trader stands |
| City religion is part of the cities section | It comes to about 310 bytes a city once several religions have spread, so 11 cities add about 3.4 KB. The available routes were too large to keep, which is why they aren't |
| The scoreboard lists unmet players as places only | World Rankings shows how many players there are, their order, and whether an unmet one leads, but not who they are |
| Each state section has its own file in `Scripts/State/` | The state grows with every section, and one file would pass 1,000 lines. A file per section keeps each one and its tests small. `include` finds a file by name in any folder, so the folder only groups the files |
