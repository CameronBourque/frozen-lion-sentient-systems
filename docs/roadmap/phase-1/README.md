# Phase 1: MVP, one agent finishes a game

The minimum viable product is the full agent loop playing a whole single-player game. Every later phase builds on it.

**Gate.** One agent plays a full single-player game against the native AI with no manual help.

## Starting point

Phase 0 is done. The bridge connects to the tuner, runs Lua in a named state, reads tagged lines, and resyncs the turn on connect. The core mod prints the turn signal, the load line, and the version. Requests from `SentientSystemsCore_UI` take effect, so the action API runs there. See [phase 0](../phase-0/README.md#results). `packages/core/bridge/scripts/gate.ts` is throwaway code that the [MCP server](mcp-server.md) step deletes.

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop.md), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md), [knowledge-files.md](../../design/knowledge-files.md).

## Steps

The `#` column sets the order, and a step's file has no number. A step is one pull request, and its tasks are its commits. Steps that share a pull request have the same title.

| # | Step | Covers | Pull request title | Status |
| --- | --- | --- | --- | --- |
| 1 | Link the core mod | A script in place of the manual junction steps | `chore(core): add the mod link script` | Done. The step file is deleted, and the steps are in the [core mod README](../../../packages/core/mod/README.md#install-for-testing) |
| 2 | Config file | Log level and provider keys | `feat(core): add the config file and structured logs` | Done. The step file is deleted, and the file is described in [settings.md](../../design/core/settings.md) |
| 3 | Logs and errors | Structured logs at five levels, a log file per game, and `ERROR` lines from the core mod | `feat(core): add the config file and structured logs` | Done. The step file is deleted. The logs are in [logs.md](../../design/core/logs.md), the `ERROR` line is under **Errors** in [design/core/mod/lines.md](../../design/core/mod/lines.md#errors), and the Lua facts are in [lua/contexts.md](../../findings/lua/contexts.md#the-core-mods-states) |
| 4 | Load signal | How the bridge tells a load has finished | `feat(core): add the load signal` | Done. The step file is deleted. The lines are under **Load signal** in [design/core/mod/lines.md](../../design/core/mod/lines.md#load-signal), the reset is under **Load reset** in [bridge.md](../../design/core/bridge.md) and **Log files** in [logs.md](../../design/core/logs.md), and the Lua facts are in [lua/state-list.md](../../findings/lua/state-list.md#state-list-over-a-session) |
| 5 | State: map, cities, and units | The serializer for one player, filtered by visibility | `feat(core): add the state serializer` | Done. The step file is deleted. The state format and the stash are under **State serializer** in [design/core/mod/state.md](../../design/core/mod/state.md) and **Stash** in [design/core/mod/json.md](../../design/core/mod/json.md#stash), and reading it is under **State** in [bridge.md](../../design/core/bridge.md). The state calls are in [state/state.md](../../findings/state/state.md), and what a player can know about each tile, the visibility layers, and the map reveal are in [state/tile-visibility.md](../../findings/state/tile-visibility.md). The Lua dialect is in [lua/contexts.md](../../findings/lua/contexts.md#lua-51-comparison), the output size limit is in [tuner/commands.md](../../findings/tuner/commands.md#what-we-know-now), and the Lua tests and coverage are under **Lint and test** in [code.md](../../rules/code.md#lint-and-test) |
| 6 | State: choices, blockers, and scoreboard | End-turn blockers, legal options and purchases with details, placement tiles, the tech and civic trees, the player's overview, diplomacy status, and victory progress | `feat(core): add blockers, choices, trees, and the scoreboard` | Done. The step file is deleted. The format of the state, the choices, the placement tiles, the trees, the blockers, the player's overview, and the scoreboard is in [design/core/mod/](../../design/core/mod/README.md), and `readPlacement` and the readers are in [bridge.md](../../design/core/bridge.md). The calls are in [state/state.md](../../findings/state/state.md), [choices/production.md](../../findings/choices/production.md), [choices/districts.md](../../findings/choices/districts.md), [choices/purchases.md](../../findings/choices/purchases.md), [choices/research.md](../../findings/choices/research.md), [choices/placement.md](../../findings/choices/placement.md), [state/player.md](../../findings/state/player.md), [state/diplomacy.md](../../findings/state/diplomacy.md), [state/scoreboard.md](../../findings/state/scoreboard.md), and [state/victories.md](../../findings/state/victories.md), and the state sizes are in [testing.md](../../design/testing.md#state-size) |
| 7 | Action API: units | The action result format, and move, stance, found city, improve, pillage, and attack, with failure reasons | `feat(core): add the unit actions` | Done. The step file is deleted. The result format, the reasons, and the unit orders are under **Action API** in [design/core/mod/actions.md](../../design/core/mod/actions.md), the calls are in [actions/move-unit.md](../../findings/actions/move-unit.md), and the parts of an action are in the [core README](../../../packages/core/README.md#parts-of-an-action) |
| 8 | Action API: unit jobs | Builder jobs, upgrades, formations, air movement, priority target, and adding production | `feat(core): add the unit job actions` | Done. The step file is deleted. The reasons and the orders are under **Action API** in [design/core/mod/actions.md](../../design/core/mod/actions.md), the calls are in [actions/unit-orders.md](../../findings/actions/unit-orders.md), and the parts of an action are in the [core README](../../../packages/core/README.md#parts-of-an-action) |
| 9 | [Action API: special units](action-api-special-units.md) | Trade routes, great people, religious units, and spy missions, with the choices they need | `feat(core): add the trade route, great person, religious unit, and spy actions` | |
| 10 | [Action API: cities](action-api-cities.md) | Production, districts and wonders, purchases, tile purchases, and the production queue | `feat(core): add the city actions` | |
| 11 | [Action API: research and policies](action-api-research-and-policies.md) | Techs, civics, policies, and a change of government | `feat(core): add the research, civic, and policy actions` | |
| 12 | [Action API: religion and rewards](action-api-religion-and-rewards.md) | The pantheon, religion, governor, envoy, great person, and artifact blockers | `feat(core): add the religion, governor, and reward actions` | |
| 13 | [Action API: other blockers](action-api-other-blockers.md) | Captured and disloyal cities, espionage, the World Congress, emergencies, and era dedications | `feat(core): add the city fate, espionage, and congress actions` | |
| 14 | [Action API: deals and end turn](action-api-deals-and-end-turn.md) | Deal responses, declaring war, and end turn, with the blocker as the reason | `feat(core): add the deal and end turn actions` | |
| 15 | [Civilopedia lookup](civilopedia-lookup.md) | Game facts from `GameInfo`, localized text, and Concepts | `feat(core): add the Civilopedia lookup` | |
| 16 | [MCP server](mcp-server.md) | State, action, and lookup tools, with a required `reason` | `feat(core): add the MCP server` | |
| 17 | [Tool reference](tool-reference.md) | `docs/reference/tools.md*` and the workflow that updates it | `ci: generate the tool reference` | |
| 18 | [Model client](model-client.md) | The Vercel AI SDK behind one interface, and `models.yaml` | `feat(core): add the model client` | |
| 19 | [Personality and sweat level](personality-and-sweat.md) | One default personality, the balanced sweat level, and the prompt | `feat: add the default personality and the balanced sweat level` | |
| 20 | [Memory and decision records](memory-and-decisions.md) | Plan and journal files, their tools, and decision records | `feat(core): add plan and journal memory` | |
| 21 | [Agent loop](agent-loop.md) | The turn, its limits, and plain code for idle units and scouts | `feat(core): add the agent loop` | |
| 22 | [Preset launcher](preset-launcher.md) | A bridge tool that starts a test preset from the main menu | `feat(core): add the preset launcher` | |
| 23 | [Smoke test](smoke-test.md) | Pass the smoke test preset | `docs: record the smoke test` | |
| 24 | [MVP gate](mvp-gate.md) | Pass the MVP gate preset, and measure the state size and the cost | `docs: record phase 1 results` | |
| 25 | [Close out phase 1](close-out.md) | Update the docs and release core | `docs: record phase 1 results` | |

The model client, personality and sweat level, and memory steps don't need the game, so they can run beside the action API and lookup steps.

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself. A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

In the smoke test and MVP gate steps, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump. The personality and sweat level PR touches `packages/core` and `packages/agents`, so its title has no scope, and both packages get a release.
