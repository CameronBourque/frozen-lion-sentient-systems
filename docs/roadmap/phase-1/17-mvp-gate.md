# Step 17: MVP gate

Pass the gate: one agent plays a full single-player game on the MVP gate preset with no manual help. Measure the state size and the cost of the game. Part of [phase 1](README.md).

## Tasks

1. **Measure the state.** Log the state size in bytes and in tokens on each turn, with each section's share. Open this commit as its own PR. Commit: `feat(core): log the state size per turn`.
2. **Run.** Start the preset with `npm run preset -- mvp-gate`, and let the agent play until the game ends in a victory or a loss. Autosave is on every turn, so a crash can resume from the last save. A resume needs no help beyond loading that save. Commit nothing yet.
3. **Fix.** For each turn that hits a limit or logs an `ERROR`, fix the cause in its own `fix:` PR. Rerun from the autosave before the bug. Commit: `fix(core): <the bug>`, one per bug.
4. **Trim.** If the state makes turns slow or costly, trim the largest sections, and move facts that `lookup` can give out of the state. See [state size](../../design/testing.md#state-size). Open each trim as its own PR. Commit: `feat(core): trim the state`.
5. **Results.** Record the game: the turns played, how it ended, the state size per era, the time per turn, the tokens and cost per turn, and the total cost. Commit: `docs: record the MVP gate results`.

## Done when

The agent finishes a full game on the MVP gate preset with no manual help, and the total cost is recorded.

## Record

- The game's numbers, in `findings/agent-runs.md`.
- The state size and any trims, in [testing.md](../../design/testing.md#state-size) and [in-game-lua.md](../../design/core/in-game-lua.md).
- The cost per game, for the mod description, in [distribution.md](../../design/distribution.md#decisions).
