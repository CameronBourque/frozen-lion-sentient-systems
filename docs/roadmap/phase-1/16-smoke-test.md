# Step 16: Smoke test

Run one agent through the smoke test preset to find the bugs that stop a game before the MVP gate costs a full game. Part of [phase 1](README.md).

## Tasks

1. **Run.** Start the preset with `npm run preset -- smoke`, with `logLevel: debug`. Let the agent play to turn 100 with no manual help. If it gets there, let it keep playing until it stops or the game ends. Commit nothing yet.
2. **Fix.** For each turn that hits a limit, logs an `ERROR`, or needs a click, fix the cause in its own `fix:` PR. Run the preset again after each fix. Commit: `fix(core): <the bug>`, one per bug.
3. **Results.** Record the run that passes, with the turns played and why it stopped, the actions per turn, the time per turn, and the cost. Commit: `docs: record the smoke test`.

## Done when

The agent plays the smoke test preset to turn 100 or later with no manual help, no `ERROR` lines, and no turn that hits a limit.

## Record

- The run's numbers, in a new finding, `findings/agent-runs.md`. Add it to the [findings index](../../findings/README.md).
- Any new limit defaults, in [turn-loop.md](../../design/agents/turn-loop.md).
