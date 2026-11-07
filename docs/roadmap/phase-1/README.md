# Phase 1: MVP, one agent finishes a game

The minimum viable product is the full agent loop playing a whole single-player game. Every later phase builds on it.

**Gate.** One agent plays a full single-player game against the native AI with no manual help.

## Starting point

Phase 0 is done. The bridge connects to the tuner, runs Lua in a named state, reads tagged lines, and resyncs the turn on connect. The core mod prints the turn signal, the load line, and the version.

Requests from `SentientSystemsCore_UI` take effect, so the action API runs there. See [phase 0](../phase-0/done.md). `packages/core/bridge/scripts/gate.ts` is throwaway code that the [MCP server](mcp-server.md) step deletes.

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop.md), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md), [knowledge-files.md](../../design/knowledge-files.md).

## Steps

The `#` column sets the order, and a step's file has no number. Each finished step has a section in [done.md](done.md). A step is one pull request, and its tasks are its commits. Steps that share a pull request have the same title.

| # | Step | Covers | Pull request title | Status |
| --- | --- | --- | --- | --- |
| 1 | Link the core mod | A script in place of the manual junction steps | `chore(core): add the mod link script` | Done. See [done.md](done.md#link-the-core-mod) |
| 2 | Config file | Log level and provider keys | `feat(core): add the config file and structured logs` | Done. See [done.md](done.md#config-file) |
| 3 | Logs and errors | Structured logs at five levels, a log file per game, and `ERROR` lines from the core mod | `feat(core): add the config file and structured logs` | Done. See [done.md](done.md#logs-and-errors) |
| 4 | Load signal | How the bridge tells a load has finished | `feat(core): add the load signal` | Done. See [done.md](done.md#load-signal) |
| 5 | State: map, cities, and units | The serializer for one player, filtered by visibility | `feat(core): add the state serializer` | Done. See [done.md](done.md#state-map-cities-and-units) |
| 6 | State: choices, blockers, and scoreboard | End-turn blockers, legal options and purchases, placement tiles, the tech and civic trees, the player's overview, diplomacy status, and victory progress | `feat(core): add blockers, choices, trees, and the scoreboard` | Done. See [done.md](done.md#state-choices-blockers-and-scoreboard) |
| 7 | Action API: units | The action result format, and move, stance, found city, improve, pillage, and attack, with failure reasons | `feat(core): add the unit actions` | Done. See [done.md](done.md#action-api-units) |
| 8 | Action API: unit jobs | Builder jobs, upgrades, formations, air movement, priority target, and adding production | `feat(core): add the unit job actions` | Done. See [done.md](done.md#action-api-unit-jobs) |
| 9 | Action API: special units | Trade routes, great people, religious units, spy missions, pillaging roads, and coastal raids, with the choices they need | `feat(core): add the trade route, great person, religious unit, and spy actions` | Done. See [done.md](done.md#action-api-special-units) |
| 10 | State: trade routes and espionage | The player's trade routes, and every spy, as the Trade Overview and Espionage screens show them | `feat(core): add the trade route and espionage state` | Done. See [done.md](done.md#state-trade-routes-and-espionage) |
| 11 | [State: unit and city details](state-unit-and-city-details.md) | What a unit is doing, its charges, religion, and great person fields, a city's religion, and the room for a new unit | `feat(core): add the unit and city details to the state` | |
| 12 | [Action API: cities](action-api-cities.md) | Production, districts and wonders, purchases, tile purchases, and the production queue | `feat(core): add the city actions` | |
| 13 | [Action API: research and policies](action-api-research-and-policies.md) | Techs, civics, policies, and a change of government | `feat(core): add the research, civic, and policy actions` | |
| 14 | [Action API: religion and rewards](action-api-religion-and-rewards.md) | The pantheon, religion, governor, envoy, great person, and artifact blockers | `feat(core): add the religion, governor, and reward actions` | |
| 15 | [Action API: other blockers](action-api-other-blockers.md) | Captured and disloyal cities, espionage, the World Congress, emergencies, and era dedications | `feat(core): add the city fate, espionage, and congress actions` | |
| 16 | [Action API: nuclear strikes](action-api-nukes.md) | The nuclear and thermonuclear stockpile, fallout and its clearing, and the strike action | `feat(core): add the nuclear actions` | |
| 17 | [Action API: deals and end turn](action-api-deals-and-end-turn.md) | Deal responses, declaring war, and end turn, with the blocker as the reason | `feat(core): add the deal and end turn actions` | |
| 18 | [Civilopedia lookup](civilopedia-lookup.md) | Game facts from `GameInfo`, localized text, and Concepts | `feat(core): add the Civilopedia lookup` | |
| 19 | [MCP server](mcp-server.md) | State, action, and lookup tools, with a required `reason` | `feat(core): add the MCP server` | |
| 20 | [Tool reference](tool-reference.md) | `docs/reference/tools.md*` and the workflow that updates it | `ci: generate the tool reference` | |
| 21 | [Model client](model-client.md) | The Vercel AI SDK behind one interface, and `models.yaml` | `feat(core): add the model client` | |
| 22 | [Personality and sweat level](personality-and-sweat.md) | One default personality, the balanced sweat level, and the prompt | `feat: add the default personality and the balanced sweat level` | |
| 23 | [Memory and decision records](memory-and-decisions.md) | Plan and journal files, their tools, and decision records | `feat(core): add plan and journal memory` | |
| 24 | [Agent loop](agent-loop.md) | The turn, its limits, and plain code for idle units and scouts | `feat(core): add the agent loop` | |
| 25 | [Preset launcher](preset-launcher.md) | A bridge tool that starts a test preset from the main menu | `feat(core): add the preset launcher` | |
| 26 | [Smoke test](smoke-test.md) | Pass the smoke test preset | `docs: record the smoke test` | |
| 27 | [MVP gate](mvp-gate.md) | Pass the MVP gate preset, and measure the state size and the cost | `docs: record phase 1 results` | |
| 28 | [Close out phase 1](close-out.md) | Update the docs and release core | `docs: record phase 1 results` | |

The model client, personality and sweat level, and memory steps don't need the game, so they can run beside the action API and lookup steps.

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself.

A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

In the smoke test and MVP gate steps, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump.

The personality and sweat level PR touches `packages/core` and `packages/agents`, so its title has no scope, and both packages get a release.
