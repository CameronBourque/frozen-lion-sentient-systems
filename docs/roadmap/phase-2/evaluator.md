# Evaluator

Add `npm run evaluate`, which turns a game's metrics lines and log into the [skill measure](skill-measure.md) report, so the smoke test and the MVP gate each record a baseline. The design is in [evaluation.md](../../design/evaluation.md). Part of [phase 2](README.md).

## Tasks

1. **Game data.** Add `src/evaluation/`, which reads one game's `metrics.jsonl` and the bridge's log, and checks each metrics line with the metrics schema. Test it with a fixture game. Commit: `feat(core): read a game's metrics and log`.
2. **Skill measures.** Compute the skill measures at each fixed turn that the game reached and at its last turn. Commit: `feat(core): compute the skill measures`.
3. **Reliability.** Compute the reliability numbers from the log. Commit: `feat(core): compute the agent's reliability numbers`.
4. **Report.** Add `npm run evaluate -- <game>`, which writes the report as JSON and as a Markdown table next to the game's log file. Commit: `feat(core): add the evaluation report`.

## Done when

`npm run evaluate` on a running game of 10 or more agent turns writes both files, and the agent's score rank on the last turn matches the **Score** tab.

## Record

- The command, where the report goes, and any measure the data can't give, in [evaluation.md](../../design/evaluation.md).
