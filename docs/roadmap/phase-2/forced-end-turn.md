# Forced end turn

Give the agent another try when `end_turn` names a blocker, and force the end of the turn when the loop hits a turn limit. The design is in [failure handling](../../design/agents/turn-loop.md#failure-handling). Part of [phase 2](README.md).

## Tasks

1. **Blockers.** When the model calls `end_turn` with a blocker left, the tool result names the blocker, and the loop gives the model another try. Each try counts against the retry limit. Done with the [agent loop](done.md#agent-loop), as step 5 of [one turn](../../design/agents/turn-loop.md#one-turn) says.
2. **Skipped blockers.** A forced end turn lists the blockers it skipped in its result. Commit: `feat(core): list the skipped blockers on a forced end turn`.
3. **Force.** When the loop hits a limit, it ends the turn with `force`, which skips any blockers left, and logs each skipped blocker as a warning. Commit: `feat(core): force the end turn at the turn limit`.

## Done when

In a running game with a blocker left and the actions per turn limit set to 1, the turn ends, and the log names each skipped blocker.

## Record

- The forced end turn at the limit, as a `## Decisions` row in [turn-loop.md](../../design/agents/turn-loop.md).
- Which blockers a forced end turn skips, in [actions/end-turn.md](../../findings/actions/end-turn.md#ending-the-turn).
