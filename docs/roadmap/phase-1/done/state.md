# Phase 1: state steps

The finished State steps of [phase 1](../README.md). The step table's `#` column sets their order.

## State: map, cities, and units

Pull request: [feat(core): add the state serializer](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/31).

It added the serializer for one player, filtered by visibility.

- The state format is under **State serializer** in [design/core/mod/state.md](../../../design/core/mod/state.md), and the stash under **Stash** in [design/core/mod/json.md](../../../design/core/mod/json.md#stash).
- Reading the state is under **State** in [bridge.md](../../../design/core/bridge.md).
- The state calls are in [state/state.md](../../../findings/state/state.md) and [state/rivals.md](../../../findings/state/rivals.md).
- What a player can know about each tile, the visibility layers, and the map reveal are in [state/tile-visibility.md](../../../findings/state/tile-visibility.md).
- The Lua dialect is in [lua/dialect.md](../../../findings/lua/dialect.md#lua-51-comparison), and the output size limit in [tuner/printing.md](../../../findings/tuner/printing.md#what-we-know-now).
- The Lua tests and coverage are under **Lint and test** in [code.md](../../../rules/code.md#lint-and-test).

## State: choices, blockers, and scoreboard

Pull request: [feat(core): add blockers, choices, trees, and the scoreboard](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/34).

It added end-turn blockers, legal options and purchases with details, placement tiles, the tech and civic trees, the player's overview, diplomacy status, and victory progress.

- The format of each is in [design/core/mod/](../../../design/core/mod/README.md), and `readPlacement` and the readers are in [bridge.md](../../../design/core/bridge.md).
- The state calls are in [state/end-turn-blockers.md](../../../findings/state/end-turn-blockers.md), [state/player.md](../../../findings/state/player.md), [state/reports.md](../../../findings/state/reports.md), [state/eras.md](../../../findings/state/eras.md), [state/diplomacy.md](../../../findings/state/diplomacy.md), [state/scoreboard.md](../../../findings/state/scoreboard.md), and [state/victories.md](../../../findings/state/victories.md).
- The choice calls are in [choices/production.md](../../../findings/choices/production.md), [choices/districts.md](../../../findings/choices/districts.md), [choices/purchases.md](../../../findings/choices/purchases.md), [choices/research.md](../../../findings/choices/research.md), and [choices/placement.md](../../../findings/choices/placement.md).
- The state sizes are in [testing.md](../../../design/testing.md#state-size).

## State: trade routes and espionage

Pull request: feat(core): add the trade route and espionage state.

It added the `trade` and `espionage` state sections, and `SentientSystems_GetCityRoutes`, which lists the routes a city could start. The Available Routes tab is too large for the state, so it is a function of one city that the MCP server step exposes.

- The sections are under **State serializer** in [design/core/mod/state.md](../../../design/core/mod/state.md).
- The calls are in [state/trade.md](../../../findings/state/trade.md) and [state/espionage.md](../../../findings/state/espionage.md).
- The parts of a state section are in the [core README](../../../../packages/core/README.md#parts-of-a-state-section).
- A spy of another player that the player holds wasn't seen in a running game, because no civ sent one. The espionage finding keeps it as an open question.

## State: unit and city details

Pull request: feat(core): add the unit and city details to the state.

It added what a unit is doing, its attacks left, builder charges, and formation, a unit's religion, religious strength, and charges, a great person's class, individual, and charges, and the religion of a visible rival religious unit.

It added each city's religion, with its majority, the followers and pressure of each religion, the pressure it exerts, and the religion it will convert to, for the player's cities and the rival cities on revealed tiles. It added each city's power with Gathering Storm.

It also fixed the `attack` action, which refused a religious unit and didn't see a unit in the religious layer of a tile.

- The room for a purchased unit is not a state field. It depends on the kind of unit, and the game's purchase check already gives its reason on each option. See [choices/purchases.md](../../../findings/choices/purchases.md#room-for-a-unit), and [choices/production.md](../../../findings/choices/production.md) for the aerodrome's room when producing.
- The fields are under **State serializer** in [design/core/mod/state.md](../../../design/core/mod/state.md), and the room's decision is in [design/core/mod/choices.md](../../../design/core/mod/choices.md).
- The calls are in [state/unit-details.md](../../../findings/state/unit-details.md) and [state/city-details.md](../../../findings/state/city-details.md), and the religious attack is in [actions/attacks.md](../../../findings/actions/attacks.md).
- The step added no state section, so the [core README](../../../../packages/core/README.md#parts-of-a-state-section) has no new row.
- A city of a rival on a revealed tile has its religion too, and it adds about 11 KB for 47 cities. If the whole state gets too large, trim its pressure fields first.
- Producing a unit that the city can't buy is as the player reports, except for an air unit. It wasn't checked for the other kinds.

## State: great works and map layers

Pull request: feat(core): add the great work and map layer state.

It added every great work slot of the player's cities with its kind, what it accepts, and its work, each building's theme and what a full theme needs, and the totals of the Great Works screen.

A function, `SentientSystems_GetGreatWorkMoves`, gives the slots a work can move to, as the screen allows. It is too large for the state.

It added three layers to the tiles: the tourism, visiting tourists, sources, and lifetime tourism of each of the player's own tiles, each revealed tile's appeal, and each tile's continent, with a `continents` section that names them. The tooltip split moved to a shared file.

- The fields are under **State serializer** in [design/core/mod/state.md](../../../design/core/mod/state.md), and the shared split is in `packages/core/mod/Scripts/SentientSystemsCore_Text.lua`.
- The calls are in [state/great-works.md](../../../findings/state/great-works.md), [state/tourism.md](../../../findings/state/tourism.md), [state/appeal.md](../../../findings/state/appeal.md), and [state/continents.md](../../../findings/state/continents.md).
- The step added a `greatWorks` and a `continents` section. The [core README](../../../../packages/core/README.md#parts-of-a-state-section) lists the parts of a section.
- The bridge doesn't call `SentientSystems_GetGreatWorkMoves` yet. The [MCP server](../mcp-server.md) step has a task for it.
- Auto theming wasn't checked, because it needs a game played as a civilization with that trait. See [state/great-works.md](../../../findings/state/great-works.md).
- The income section has its own copy of the tooltip split. See [tech-debt](../../../tech-debt/share-tooltip-lines.md).
