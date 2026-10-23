# Phase 1: MVP, one agent finishes a game

The minimum viable product is the full agent loop playing a whole single-player game. Every later phase builds on it.

**Gate.** One agent plays a full single-player game against the native AI with no manual help.

## Starting point

Phase 0 is done. The bridge connects to the tuner, runs Lua in a named state, reads tagged lines, and resyncs the turn on connect. The core mod prints the turn signal, the load line, and the version. Requests from `SentientSystemsCore_UI` take effect, so the action API runs there. See [phase 0](../phase-0/README.md#results). `packages/core/bridge/scripts/gate.ts` is throwaway code that step 9 deletes.

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop.md), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md), [knowledge-files.md](../../design/knowledge-files.md).

## Steps

| # | Step | Covers | Status |
| --- | --- | --- | --- |
| 1 | Link the core mod | A script in place of the manual junction steps | Done. The step file is deleted, and the steps are in the [core mod README](../../../packages/core/mod/README.md#install-for-testing) |
| 2 | [Config file](02-config-file.md) | Agent slot, log level, provider, and API key | |
| 3 | [Logs and errors](03-logs-and-errors.md) | Three log levels, a log file per game, and `ERROR` lines from the core mod | |
| 4 | [Load signal](04-load-signal.md) | How the bridge tells a load has finished | |
| 5 | [State: map, cities, and units](05-state-map-cities-units.md) | The serializer for one player, filtered by visibility | |
| 6 | [State: choices, blockers, and scoreboard](06-state-choices-blockers-scoreboard.md) | Legal options with details, end-turn blockers, and victory progress | |
| 7 | [Action API](07-action-api.md) | Units, production, techs, civics, policies, and end turn, with failure reasons | |
| 8 | [Civilopedia lookup](08-civilopedia-lookup.md) | Game facts from `GameInfo`, localized text, and Concepts | |
| 9 | [MCP server](09-mcp-server.md) | State, action, and lookup tools, with a required `reason` | |
| 10 | [Tool reference](10-tool-reference.md) | `docs/reference/tools.md` and the workflow that updates it | |
| 11 | [Model client](11-model-client.md) | The Vercel AI SDK behind one interface, and `models.yaml` | |
| 12 | [Personality and sweat level](12-personality-and-sweat.md) | One default personality, the balanced sweat level, and the prompt | |
| 13 | [Memory and decision records](13-memory-and-decisions.md) | Plan and journal files, their tools, and decision records | |
| 14 | [Agent loop](14-agent-loop.md) | The turn, its limits, and plain code for idle units and scouts | |
| 15 | [Preset launcher](15-preset-launcher.md) | A bridge tool that starts a test preset from the main menu | |
| 16 | [Smoke test](16-smoke-test.md) | Pass the smoke test preset | |
| 17 | [MVP gate](17-mvp-gate.md) | Pass the MVP gate preset, and measure the state size and the cost | |
| 18 | [Close out phase 1](18-close-out.md) | Update the docs and release core | |

Steps 11 to 13 don't need the game, so they can run beside steps 4 to 8.

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself. A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

| PR | Steps | Title |
| --- | --- | --- |
| 1 | 1 | `chore(core): add the mod link script` |
| 2 | 2 and 3 | `feat(core): add the config file and log levels` |
| 3 | 4 | `feat(core): add the load signal` |
| 4 | 5 and 6 | `feat(core): add the state serializer` |
| 5 | 7 | `feat(core): add the action API` |
| 6 | 8 | `feat(core): add the Civilopedia lookup` |
| 7 | 9 | `feat(core): add the MCP server` |
| 8 | 10 | `ci: generate the tool reference` |
| 9 | 11 | `feat(core): add the model client` |
| 10 | 12 | `feat: add the default personality and the balanced sweat level` |
| 11 | 13 | `feat(core): add plan and journal memory` |
| 12 | 14 | `feat(core): add the agent loop` |
| 13 | 15 | `feat(core): add the preset launcher` |
| 14 | 16 | `docs: record the smoke test` |
| 15 | 17 and 18 | `docs: record phase 1 results` |

In steps 16 and 17, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump. PR 10 touches `packages/core` and `packages/agents`, so its title has no scope, and both packages get a release.
