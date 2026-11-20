# Close out phase 2

Close the phase in the docs, and release core and the agent players mod. Part of [phase 2](README.md).

## Tasks

1. **Close the phase.** Follow the steps in [rules/docs.md](../../rules/docs.md#roadmap). Commit: `docs: close phase 2`.
2. **Risks.** In [risks.md](../../risks.md), update the game state and cost per game rows with the measured numbers from `docs/findings/agent-runs.md`. Commit: `docs: update the state size and cost risks`.
3. **Release.** Merge the release-please PRs for core and for the agent players mod.

## Done when

All of these hold, and core and the agent players mod each have a release:

- In a running game, the released executable plays 10 turns in a row with no manual help. The log shows each tool call with its `reason`, and no turn hits a limit.
- Every step's status is Done.

## Record

Nothing new. The steps above update the docs.
