# Phase 2: MVP, one agent finishes a game

The minimum viable product is the full agent loop playing a whole single-player game. The loop calls the model and the MCP tools from [phase 1](../phase-1/README.md) itself, so no one prompts it. Every later phase builds on it.

**Gate.** One agent plays a full single-player game against the native AI with no manual help.

## Starting point

Phase 1 is done. The MCP server serves the state, the action API, and the lookup as tools, and Claude Code has played 10 turns through them.

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop.md), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md), [knowledge-files.md](../../design/knowledge-files.md).

## Steps

The `#` column sets the order, and a step's file has no number. A step is one pull request, and its tasks are its commits. Steps that share a pull request have the same title.

| # | Step | Covers | Pull request title | Status |
| --- | --- | --- | --- | --- |
| 1 | [Model client](model-client.md) | The Vercel AI SDK behind one interface, and the model picker | `feat(core): add the model client` | |
| 2 | [Personality and sweat level](personality-and-sweat.md) | One default personality, the balanced sweat level, and the prompt | `feat: add the default personality and the balanced sweat level` | |
| 3 | [Memory and decision records](memory-and-decisions.md) | Plan and journal files, their tools, and decision records | `feat(core): add plan and journal memory` | |
| 4 | [Agent loop](agent-loop.md) | The MCP tools for the model, one agent turn, and the turn signal | `feat(core): add the agent loop` | |
| 5 | [End turn](end-turn.md) | Wait for the turn to change, a turn that starts again, and a game load | `feat(core): play turn after turn` | |
| 6 | [Turn limits](turn-limits.md) | Retries per action, actions per turn, and time per turn | `feat(core): add turn limits` | |
| 7 | [Forced end turn](forced-end-turn.md) | Another try after a blocked end turn, and a forced end at a limit | `feat(core): force the end turn at the turn limit` | |
| 8 | [Idle units and scouts](idle-units.md) | Fortify idle military units and set scouts to explore in plain code | `feat(core): handle idle units and scouts in plain code` | |
| 9 | [Game options](game-options.md) | Warn when quick movement or quick combat is off | `feat(core): warn when quick movement or quick combat is off` | |
| 10 | [Stopping and spending limits](stopping.md) | The stop key, a turn count, and cost limits per turn and per run | `feat(core): add the stop key and spending limits` | |
| 11 | [Metrics line](metrics-line.md) | A line with each player's score after each agent turn, for the baseline | `feat(core): add the metrics line` | |
| 12 | [Yield and empire metrics](metrics-yields.md) | Yields, military strength, cities, population, techs, and civics | `feat(core): add yields and empire counts to the metrics` | |
| 13 | [Era and victory metrics](metrics-victories.md) | The era, era score, age, and progress toward each victory | `feat(core): add the era and victory progress to the metrics` | |
| 14 | [Skill measure](skill-measure.md) | How strong and reliable the agent's play is, apart from the sweat level targets | `docs: add the skill measure` | |
| 15 | [Evaluator](evaluator.md) | `npm run evaluate`, which writes the skill measure report for a game | `feat(core): add the evaluator` | |
| 16 | [Front-end probe](front-end-probe.md) | How the front end starts a game, and whether the core mod can drive it | `feat(core): report the front-end screen` | |
| 17 | [Preset launcher](preset-launcher.md) | A bridge tool that starts a test preset from the main menu | `feat(core): add the preset launcher` | |
| 18 | [Smoke test](smoke-test.md) | Pass the smoke test preset, and record the first baseline | `docs: record the smoke test` | |
| 19 | [MVP gate](mvp-gate.md) | Pass the MVP gate preset, and measure the state size, the cost, and the baseline | `docs: record phase 2 results` | |
| 20 | [Close out phase 2](close-out.md) | Update the docs, and release core and the agent players mod | `docs: record phase 2 results` | |

The model client, personality and sweat level, memory, and skill measure steps don't need the game, so they can run beside the steps that do.

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself.

A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

In the smoke test and MVP gate steps, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump.

The personality and sweat level PR touches `packages/core` and `packages/agents`, so its title has no scope, and both packages get a release.
