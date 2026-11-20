# Metrics line

Write a metrics line with the score for each player after each agent turn, so the MVP gate game is the baseline that phase 4 changes are measured against. The [yield and empire metrics](metrics-yields.md) and the [era and victory metrics](metrics-victories.md) add the other numbers. The design is in [evaluation.md](../../design/evaluation.md#metrics-line). Part of [phase 2](README.md).

## Tasks

1. **Metrics call.** Add `SentientSystems_GetMetrics()` to the core mod. It returns the score and its 7 categories, as the Score tab shows them, for every major player, met or not, through the [stash](../../design/core/mod/json.md#stash).

   Give it a `zod` schema in `src/metrics/`, which the contract test checks against a Lua fixture. Commit: `feat(core): add the metrics call`.
2. **Metrics file.** After each agent turn ends, read the metrics and append one JSON line for each player to `metrics.jsonl`, next to the game's log file. Phase 2 has no checkpoint IDs, so each line carries the turn number only. Commit: `feat(core): write the metrics lines`.

## Done when

After 3 agent turns in a running game, `metrics.jsonl` holds 3 lines for each major player, and the agent's score matches the **Score** tab.

## Record

- The calls that give the score for players the agent hasn't met, in [evaluation.md](../../design/evaluation.md#metrics-line).
