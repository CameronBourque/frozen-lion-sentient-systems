# Phase 1: finished steps

The steps of [phase 1](README.md) that are done, each with the pull request it merged in, what it delivered, and where its results live. The step table's `#` column sets their order.

## Link the core mod

Pull request: [chore(core): add the mod link script](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/26).

It added a script in place of the manual junction steps. The steps are in the [core mod README](../../../packages/core/mod/README.md#install-for-testing).

## Config file

Pull request: [feat(core): add the config file and structured logs](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/27), shared with the logs and errors step.

It added the log level and the provider keys. The file is described in [settings.md](../../design/core/settings.md).

## Logs and errors

Pull request: [feat(core): add the config file and structured logs](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/27), shared with the config file step.

It added structured logs at five levels, a log file per game, and `ERROR` lines from the core mod.

- The logs are in [logs.md](../../design/core/logs.md).
- The `ERROR` line is under **Errors** in [design/core/mod/lines.md](../../design/core/mod/lines.md#errors).
- The Lua facts are in [lua/contexts.md](../../findings/lua/contexts.md#the-core-mods-states).

## Load signal

Pull request: [feat(core): add the load signal](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/29).

It lets the bridge tell when a load has finished.

- The lines are under **Load signal** in [design/core/mod/lines.md](../../design/core/mod/lines.md#load-signal).
- The reset is under **Load reset** in [bridge.md](../../design/core/bridge.md), and under **Log files** in [logs.md](../../design/core/logs.md).
- The Lua facts are in [lua/state-list.md](../../findings/lua/state-list.md#state-list-over-a-session).

## State: map, cities, and units

Pull request: [feat(core): add the state serializer](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/31).

It added the serializer for one player, filtered by visibility.

- The state format is under **State serializer** in [design/core/mod/state.md](../../design/core/mod/state.md), and the stash under **Stash** in [design/core/mod/json.md](../../design/core/mod/json.md#stash).
- Reading the state is under **State** in [bridge.md](../../design/core/bridge.md).
- The state calls are in [state/state.md](../../findings/state/state.md) and [state/rivals.md](../../findings/state/rivals.md).
- What a player can know about each tile, the visibility layers, and the map reveal are in [state/tile-visibility.md](../../findings/state/tile-visibility.md).
- The Lua dialect is in [lua/dialect.md](../../findings/lua/dialect.md#lua-51-comparison), and the output size limit in [tuner/printing.md](../../findings/tuner/printing.md#what-we-know-now).
- The Lua tests and coverage are under **Lint and test** in [code.md](../../rules/code.md#lint-and-test).

## State: choices, blockers, and scoreboard

Pull request: [feat(core): add blockers, choices, trees, and the scoreboard](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/34).

It added end-turn blockers, legal options and purchases with details, placement tiles, the tech and civic trees, the player's overview, diplomacy status, and victory progress.

- The format of each is in [design/core/mod/](../../design/core/mod/README.md), and `readPlacement` and the readers are in [bridge.md](../../design/core/bridge.md).
- The state calls are in [state/end-turn-blockers.md](../../findings/state/end-turn-blockers.md), [state/player.md](../../findings/state/player.md), [state/reports.md](../../findings/state/reports.md), [state/eras.md](../../findings/state/eras.md), [state/diplomacy.md](../../findings/state/diplomacy.md), [state/scoreboard.md](../../findings/state/scoreboard.md), and [state/victories.md](../../findings/state/victories.md).
- The choice calls are in [choices/production.md](../../findings/choices/production.md), [choices/districts.md](../../findings/choices/districts.md), [choices/purchases.md](../../findings/choices/purchases.md), [choices/research.md](../../findings/choices/research.md), and [choices/placement.md](../../findings/choices/placement.md).
- The state sizes are in [testing.md](../../design/testing.md#state-size).

## Action API: units

Pull request: [feat(core): add the unit actions](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/45).

It added the action result format, and move, stance, found city, improve, pillage, and attack, with failure reasons.

- The result format, the reasons, and the unit orders are under **Action API** in [design/core/mod/actions.md](../../design/core/mod/actions.md).
- The calls are in [actions/move-unit.md](../../findings/actions/move-unit.md), [actions/unit-orders.md](../../findings/actions/unit-orders.md), and [actions/attacks.md](../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../packages/core/README.md#parts-of-an-action).

## Action API: unit jobs

Pull request: [feat(core): add the unit job actions](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/56).

It added builder jobs, upgrades, formations, air movement, the priority target, and adding production.

- The reasons and the orders are under **Action API** in [design/core/mod/actions.md](../../design/core/mod/actions.md).
- The calls are in [actions/unit-orders.md](../../findings/actions/unit-orders.md), [actions/builder-jobs.md](../../findings/actions/builder-jobs.md), [actions/formations.md](../../findings/actions/formations.md), [actions/air-moves.md](../../findings/actions/air-moves.md), and [actions/attacks.md](../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../packages/core/README.md#parts-of-an-action).

## Action API: special units

Pull request: feat(core): add the trade route, great person, religious unit, and spy actions.

It added the trade route and spy choices, and the trade route, plunder, great person, religious unit, spy, pillage road, and coastal raid actions.

- The reasons and the orders are under **Action API** in [design/core/mod/actions.md](../../design/core/mod/actions.md), and the choices are in [design/core/mod/choices.md](../../design/core/mod/choices.md).
- The choices' calls are in [choices/trade-routes.md](../../findings/choices/trade-routes.md) and [choices/spy-missions.md](../../findings/choices/spy-missions.md).
- The actions' calls are in [actions/trade.md](../../findings/actions/trade.md), [actions/great-people.md](../../findings/actions/great-people.md), [actions/spies.md](../../findings/actions/spies.md), [actions/religious-units.md](../../findings/actions/religious-units.md), [actions/unit-orders.md](../../findings/actions/unit-orders.md), and [actions/attacks.md](../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../packages/core/README.md#parts-of-an-action).
