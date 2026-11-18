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
| 1 | [Model client](model-client.md) | The Vercel AI SDK behind one interface, and `models.yaml` | `feat(core): add the model client` | |
| 2 | [Personality and sweat level](personality-and-sweat.md) | One default personality, the balanced sweat level, and the prompt | `feat: add the default personality and the balanced sweat level` | |
| 3 | [Memory and decision records](memory-and-decisions.md) | Plan and journal files, their tools, and decision records | `feat(core): add plan and journal memory` | |
| 4 | [Agent loop](agent-loop.md) | The turn, its limits, and plain code for idle units and scouts | `feat(core): add the agent loop` | |
| 5 | [Stopping and spending limits](stopping.md) | The stop key, a turn count, and cost limits per turn and per run | `feat(core): add the stop key and spending limits` | |
| 6 | [Metrics line](metrics-line.md) | One line of numbers for each player after each agent turn, for the baseline | `feat(core): add the metrics line` | |
| 7 | [Preset launcher](preset-launcher.md) | A bridge tool that starts a test preset from the main menu | `feat(core): add the preset launcher` | |
| 8 | [Smoke test](smoke-test.md) | Pass the smoke test preset | `docs: record the smoke test` | |
| 9 | [MVP gate](mvp-gate.md) | Pass the MVP gate preset, and measure the state size and the cost | `docs: record phase 2 results` | |
| 10 | [Close out phase 2](close-out.md) | Update the docs, and release core and the agent players mod | `docs: record phase 2 results` | |

The model client, personality and sweat level, and memory steps don't need the game, so they can run beside the phase 1 steps.

## Commits and pull requests

Each task in a step file is one commit, and the task names its subject line. Each commit holds its own tests and passes `npm run lint`, `npm run coverage`, `npm run typecheck`, and `npm run check-docs` by itself.

A commit that finds a fact also updates the finding or design file in the step's `## Record`.

Pull requests are squash-merged, so each PR title becomes one commit on `main`. Titles follow [rules/commits.md](../../rules/commits.md).

In the smoke test and MVP gate steps, each code change gets its own `fix:` or `feat:` PR before the step's results PR, because a `docs:` title would drop its version bump.

The personality and sweat level PR touches `packages/core` and `packages/agents`, so its title has no scope, and both packages get a release.
