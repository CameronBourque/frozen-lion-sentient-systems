# Phase 1: Agent tools over MCP

Core reads the game, runs every action a player can take, and serves both as MCP tools. An outside MCP client, such as Claude Code, can then play the game, with you prompting each turn. The [agent loop](../phase-2/README.md) in phase 2 calls the same tools.

**Gate.** From Claude Code, play 10 turns of a single-player game through the MCP server, with a `reason` on every action.

## Starting point

Phase 0 is done. The bridge connects to the tuner, runs Lua in a named state, reads tagged lines, and resyncs the turn on connect. The core mod prints the turn signal, the load line, and the version.

Requests from `SentientSystemsCore_UI` take effect, so the action API runs there. See [phase 0](../phase-0/done.md).

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop.md#tools).

## Steps

The `#` column sets the order, and a step's file has no number. Each finished step has a section in [done/](done/README.md). A step is one pull request, and its tasks are its commits. Steps that share a pull request have the same title.

| # | Step | Covers | Pull request title | Status |
| --- | --- | --- | --- | --- |
| 1 | Link the core mod | A script in place of the manual junction steps | `chore(core): add the mod link script` | Done. See [setup.md](done/setup.md#link-the-core-mod) |
| 2 | Config file | Log level and provider keys | `feat(core): add the config file and structured logs` | Done. See [setup.md](done/setup.md#config-file) |
| 3 | Logs and errors | Structured logs at five levels, a log file per game, and `ERROR` lines from the core mod | `feat(core): add the config file and structured logs` | Done. See [setup.md](done/setup.md#logs-and-errors) |
| 4 | Load signal | How the bridge tells a load has finished | `feat(core): add the load signal` | Done. See [setup.md](done/setup.md#load-signal) |
| 5 | State: map, cities, and units | The serializer for one player, filtered by visibility | `feat(core): add the state serializer` | Done. See [state.md](done/state.md#state-map-cities-and-units) |
| 6 | State: choices, blockers, and scoreboard | End-turn blockers, legal options and purchases, placement tiles, the tech and civic trees, the player's overview, diplomacy status, and victory progress | `feat(core): add blockers, choices, trees, and the scoreboard` | Done. See [state.md](done/state.md#state-choices-blockers-and-scoreboard) |
| 7 | Action API: units | The action result format, and move, stance, found city, improve, pillage, and attack, with failure reasons | `feat(core): add the unit actions` | Done. See [unit-actions.md](done/unit-actions.md#action-api-units) |
| 8 | Action API: unit jobs | Builder jobs, upgrades, formations, air movement, priority target, and adding production | `feat(core): add the unit job actions` | Done. See [unit-actions.md](done/unit-actions.md#action-api-unit-jobs) |
| 9 | Action API: special units | Trade routes, great people, religious units, spy missions, pillaging roads, and coastal raids, with the choices they need | `feat(core): add the trade route, great person, religious unit, and spy actions` | Done. See [unit-actions.md](done/unit-actions.md#action-api-special-units) |
| 10 | State: trade routes and espionage | The player's trade routes, and every spy, as the Trade Overview and Espionage screens show them | `feat(core): add the trade route and espionage state` | Done. See [state.md](done/state.md#state-trade-routes-and-espionage) |
| 11 | State: unit and city details | What a unit is doing, its charges, religion, and great person fields, and a city's religion and power | `feat(core): add the unit and city details to the state` | Done. See [state.md](done/state.md#state-unit-and-city-details) |
| 12 | State: great works and map layers | Every great work slot with its city and work, where a work can move, and the tourism, appeal, and continent of each tile | `feat(core): add the great work and map layer state` | Done. See [state.md](done/state.md#state-great-works-and-map-layers) |
| 13 | Action API: cities | Production, districts and wonders, purchases, tile purchases, and the production queue | `feat(core): add the city actions` | Done. See [empire-actions.md](done/empire-actions.md#action-api-cities) |
| 14 | Action API: research and policies | Techs and civics with their queues, policies, the paid policy unlock, and a change of government | `feat(core): add the research, civic, policy, and government actions` | Done. See [empire-actions.md](done/empire-actions.md#action-api-research-and-policies) |
| 15 | Action API: religion and rewards | The pantheon, great person, religion, governor, and envoy blockers | `feat(core): add the religion, governor, and reward actions` | Done. See [empire-actions.md](done/empire-actions.md#action-api-religion-and-rewards) |
| 16 | Action API: great works | Moving a great work between slots, and choosing an artifact | `feat(core): add the great work and artifact actions` | Done. See [empire-actions.md](done/empire-actions.md#action-api-great-works) |
| 17 | Action API: other blockers | Captured and disloyal cities, espionage, the World Congress, and era dedications | `feat(core): add the city fate, espionage, congress, and dedication actions` | Done. See [turn-actions.md](done/turn-actions.md#action-api-other-blockers) |
| 18 | Action API: nuclear strikes | The nuclear and thermonuclear stockpile, the launchers, the strike from a unit or a silo, and fallout and its clearing | `feat(core): add the nuclear actions` | Done. See [unit-actions.md](done/unit-actions.md#action-api-nuclear-strikes) |
| 19 | Action API: deals and end turn | End turn with the blocker as the reason, deal responses, declaring war, and proposing peace | `feat(core): add the deal and end turn actions` | Done. See [turn-actions.md](done/turn-actions.md#action-api-deals-and-end-turn) |
| 20 | Diplomacy sessions | The sessions an AI opens with no deal, such as a comment, a request for a promise, or a first meeting, in the state, with an action that answers one | `feat(core): add the diplomacy session state and action` | Done. See [turn-actions.md](done/turn-actions.md#diplomacy-sessions) |
| 21 | Popups for agent players | Skip, turn off, or close each popup that waits for a click, such as the wonder, disaster, tech, hero, era, World Congress, and spy mission popups, for an agent player | `feat(core): close the popups for agent players` | Done. See [popups.md](done/popups.md#popups-for-agent-players) |
| 22 | Civilopedia lookup | Search, pages, and browsing over the Civilopedia's tables, `GameInfo`, and localized text, Concepts included | `feat(core): add the Civilopedia lookup` | Done. See [lookup.md](done/lookup.md#civilopedia-lookup) |
| 23 | MCP server | State, on-demand state, action, and lookup tools, with a required `reason` | `feat(core): add the MCP server` | Done. See [mcp-server.md](done/mcp-server.md#mcp-server) |
| 24 | [Tool reference](tool-reference.md) | `docs/reference/tools.md` and the workflow that updates it | `ci: generate the tool reference` | |
| 25 | [Claude Code gate](claude-code-gate.md) | Play 10 turns from Claude Code through the MCP server | `docs: record phase 1 results` | |
| 26 | [Close out phase 1](close-out.md) | Update the docs. No release | `docs: record phase 1 results` | |

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself.

A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

In the Claude Code gate step, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump.
