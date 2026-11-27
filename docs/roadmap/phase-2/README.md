# Phase 2: MVP, one agent finishes a game

The minimum viable product is the full agent loop playing a whole single-player game. The loop calls the model and the MCP tools from [phase 1](../phase-1/README.md) itself, so no one prompts it. Every later phase builds on it.

**Gate.** One agent plays a full single-player game against the native AI with no manual help.

## Starting point

Phase 1 is done. The MCP server serves the state, the action API, and the lookup as tools, and Claude Code has played 10 turns through them.

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop/README.md), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md), [knowledge-files.md](../../design/knowledge-files.md).

## Steps

The `#` column sets the order, and a step's file has no number. A step is one pull request, and its tasks are its commits. Steps that share a pull request have the same title.

| # | Step | Covers | Pull request title | Status |
| --- | --- | --- | --- | --- |
| 1 | Model client | The Vercel AI SDK behind one interface, and the model picker | `feat(core): add the model client` | Done. See [done.md](done.md#model-client) |
| 2 | Personality and sweat level | The neutral personality, the balanced sweat level, and the prompt | `feat(core): add the neutral personality and the balanced sweat level` | Done. See [done.md](done.md#personality-and-sweat-level) |
| 3 | Memory and decision records | Plan and journal files, their tools, and decision records | `feat(core): add plan and journal memory` | Done. See [done.md](done.md#memory-and-decision-records) |
| 4 | Run mode menu | A file for each provider and the four run modes in the picker, with only the API key working | `feat(core): add the run mode menu` | Done. See [done.md](done.md#run-mode-menu) |
| 5 | ChatGPT plan | The subscription token mode for OpenAI: sign-in, token refresh, and plan calls | `feat(core): run agents on a ChatGPT plan` | Done. See [done.md](done.md#chatgpt-plan) |
| 6 | xAI provider | xAI as a fourth provider in the API key mode, for Grok models | `feat(core): add xAI as a provider` | Done. See [done.md](done.md#xai-provider) |
| 7 | Agent loop | The MCP tools for the model, one agent turn, and the turn signal | `feat(core): add the agent loop` | Done. See [done.md](done.md#agent-loop) |
| 8 | End turn | Wait for the turn to change, a turn that starts again, and a game load | `feat(core): play turn after turn` | Done. See [done.md](done.md#end-turn) |
| 9 | Turn limits | Retries per action, actions per turn, and time per turn | `feat(core): add turn limits` | Done. See [done.md](done.md#turn-limits) |
| 10 | [Forced end turn](forced-end-turn.md) | Another try after a blocked end turn, and a forced end at a limit | `feat(core): force the end turn at the turn limit` | |
| 11 | [Idle units and scouts](idle-units.md) | Fortify idle military units and set scouts to explore in plain code | `feat(core): handle idle units and scouts in plain code` | |
| 12 | [Game options](game-options.md) | Warn when quick movement or quick combat is off | `feat(core): warn when quick movement or quick combat is off` | |
| 13 | [Stopping and spending limits](stopping.md) | The stop key, a turn count, and cost limits per turn and per run | `feat(core): add the stop key and spending limits` | |
| 14 | [Claude runner](claude-agent-sdk.md) | The agent runner, and the Claude Agent SDK runner behind a flag | `feat(core): run Claude agents through the Agent SDK` | |
| 15 | [Metrics line](metrics-line.md) | A line with each player's score after each agent turn, for the baseline | `feat(core): add the metrics line` | |
| 16 | [Yield and empire metrics](metrics-yields.md) | Yields, military strength, cities, population, techs, and civics | `feat(core): add yields and empire counts to the metrics` | |
| 17 | [Era and victory metrics](metrics-victories.md) | The era, era score, age, and progress toward each victory | `feat(core): add the era and victory progress to the metrics` | |
| 18 | [Skill measure](skill-measure.md) | How strong and reliable the agent's play is, apart from the sweat level targets | `docs: add the skill measure` | |
| 19 | [Evaluator](evaluator.md) | `npm run evaluate`, which writes the skill measure report for a game | `feat(core): add the evaluator` | |
| 20 | [Front-end probe](front-end-probe.md) | How the front end starts a game, and whether the core mod can drive it | `feat(core): report the front-end screen` | |
| 21 | [Preset launcher](preset-launcher.md) | A bridge tool that starts a test preset from the main menu | `feat(core): add the preset launcher` | |
| 22 | [Action changes](action-changes.md) | Action results that carry the records the action changed | `feat(core): report what each action changed` | |
| 23 | [Smoke test](smoke-test.md) | Pass the smoke test preset, and record the first baseline | `docs: record the smoke test` | |
| 24 | [MVP gate](mvp-gate.md) | Pass the MVP gate preset, and measure the state size, the cost, and the baseline | `docs: record phase 2 results` | |
| 25 | [Close out phase 2](close-out.md) | Update the docs, and release core and the agent players mod | `docs: record phase 2 results` | |

The model client, personality and sweat level, memory, run mode menu, ChatGPT plan, xAI provider, and skill measure steps don't need the game, so they can run beside the steps that do.

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself.

A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

In the smoke test and MVP gate steps, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump.
