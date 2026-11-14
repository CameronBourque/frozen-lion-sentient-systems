# Core mod state

How the core mod builds one player's view of the game. Part of the [core mod](README.md).

## State serializer

It builds a view of one player's game from that player's own visibility data, never from what is on screen. A map reveal that changes only the view can then never leak hidden information to an agent.

A reveal that writes the player's visibility data, such as FireTuner's **Reveal All**, does leak it. See [findings/state/tile-visibility.md](../../../findings/state/tile-visibility.md#firetuners-map-reveal).

The view holds what a player sees on these screens, grouped by screen. The list below shows what it holds now, and the [roadmap](../../../roadmap/README.md) says when the rest comes:

- **The map.** Revealed tiles, the player's units, and the rival cities and units the player can see, with the religion of each city and the religion and religious strength of a religious rival unit.

  Each unit has what it is doing, its attacks left, its builder charges, and its formation. A religious unit has its religion, its religious strength, and its spread and heal charges, and a great person its class, individual, and action charges.
- **The city panel, and the City Status tab of Reports.** Each city's yields, growth, housing, amenities, loyalty, defense, districts, production, growth rate status, war weariness, governor, power, and religion.

  A city's power is its status, the usable and required power, and what gives it power and needs it, with Gathering Storm. A city's religion is its majority, the pressure it exerts, the religion it will convert to and when, and the followers and pressure of each religion present.
- **The Next Turn button.** What blocks the end of the turn.
- **The top bar.** The gold and faith balances, the science, culture, faith, gold, and tourism per turn, the trade route capacity, the nuclear and thermonuclear devices, and, with Gathering Storm, diplomatic favor.
- **The unit panel and the missile silo banner.** For each device the player has, the units and silos that can launch it now.
- **The Yields tab of Reports.** Income by source, building and unit upkeep, deal payments, and net income per turn.
- **The Resources tab of Reports.** Strategic and luxury resources, and, with Gathering Storm, strategic stockpiles.
- **The Gossip tab of Reports.** What the player has heard about met players.
- **The Era Progress panel.** The era, era score, current age, the thresholds for the next age, turns until the next era, and the active effects.
- **The Great People screen.** Each candidate's era and effect, each met player's recruit progress, points per turn, and the gold and faith patronage costs.
- **The City-States screen.** Envoy tokens, the bonuses of each kind of city-state, and each city-state's envoys, suzerain, suzerain bonus, resources, quests, and the players with envoys there.
- **The Governors panel.** The appointed governors, their cities, and their promotions.
- **The Religion screen.** The pantheon, the religion, and its followers.
- **The diplomacy screens.** War or peace with each met player, proposed deals, relationships, grievances, and agendas.

  The leader screens that offer an agent player only a goodbye, such as a comment, are closed by the core mod as they arrive. What the leader said stays with that player until the end of the next turn. It is lost when the game loads.

  The other leader screens open with the player, such as a request or a first meeting, are their own section, with what the leader says and the options the screen offers.

  No game call returns a screen's statement, so the core mod keeps it as it arrives. After a load it lists an open screen as unknown, which only the goodbye can close.
- **The Trade Overview.** The player's routes, with the yields of both ends, the routes of other players that end in the player's cities, and the tourism bonus of a route.

  Its Available Routes tab is too large for the state, so `SentientSystems_GetCityRoutes` returns it for one city on demand.
- **The Espionage screen.** The spy capacity, each spy of the player: idle, on a mission, traveling, or captured, the districts and Gain Sources boosts of the other majors' cities, the last 10 missions with their outcomes and loot, and the other players' spies the player holds.
- **The Great Works screen.** Every great work slot of the player's cities with its kind and work, each building's theming progress, and the totals: the works, the display spaces, and what they provide.

  Where a work can move is too large for the state, so `SentientSystems_GetGreatWorkMoves` returns it for one work on demand.
- **The Tourism lens.** On each of the player's own tiles with tourism: the tourism each turn, the visiting tourists, what gives it, and the lifetime tourism, as the lens's banner and its tooltip show them.
- **The Appeal lens.** On each revealed land tile and natural wonder: its appeal, as the tooltip and the lens show it, left out when 0.
- **The plot tooltip.** On each revealed tile with nuclear fallout: the turns it has left.
- **The Continent lens.** The index of each tile's continent, and a list of the continents the player has revealed with their types and names, as the lens and the tooltip show them.
- **Their own screens.** Climate and disasters.
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
| Where a great work can move is a function of one work, not a state section | Every movable work lists the slots it fits or swaps with, 191 in one game and about 26 KB once the art unlocks, more than the section itself. One work is under 2 KB, and the move action can check a request with it |
| City religion is part of the cities and rivals sections | It comes to about 310 bytes a city, so 11 cities add about 3.4 KB. A rival city on a revealed tile has it too, as its banner shows it, at about 230 bytes, which is 11 KB for 47 cities |
| The scoreboard lists unmet players as places only | World Rankings shows how many players there are, their order, and whether an unmet one leads, but not who they are |
| WMD launchers are their own section, grouped by device | It answers what can launch a device now, with no field on every unit and tile. 100 launchers take 2 KB grouped, or 8.5 KB as one entry each. With no devices it is left out, and skips the checks |
| The core mod closes a goodbye-only leader screen, and the diplomacy section keeps what the leader said | The AI turns wait while a session is open. A human sees the text, so the agent does too, until the [computer slot test](../../agents/slot-type.md#computer-slot-test) shows what an AI gets. Messages are small, so they share the section |
| The leader screens with a choice are their own section, apart from diplomacy | Like a proposal, each is a decision that waits for the agent, and the AI turns wait with it. The messages record what happened, so they stay in diplomacy |
| Each state section has its own file in `Scripts/State/` | The state grows with every section, and one file would pass 1,000 lines. A file per section keeps each one and its tests small. `include` finds a file by name in any folder, so the folder only groups the files |
