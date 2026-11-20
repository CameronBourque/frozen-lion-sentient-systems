# Skill measure

Design a measure of how well an agent plays, apart from the sweat level targets, so each run gets a baseline that later runs and other models can be compared with. The design is in [evaluation.md](../../design/evaluation.md). Part of [phase 2](README.md).

The sweat level targets judge an agent by its distance from its band, so a balanced agent far ahead of every rival misses its target. The skill measure judges only how strong and how reliable the play is.

## Tasks

1. **Skill measures.** Add a `## Skill measure` section to [evaluation.md](../../design/evaluation.md). It compares the agent with the native AI players on the same game at fixed turns, such as 50, 100, 150, and the last turn, so runs on the same preset and seeds compare turn for turn.

   It lists the measures: score rank and the score ratio to the best native AI, science, culture, and production per turn as ratios to the median, and the number of cities and the total population. Commit: `docs: add the skill measure`.
2. **Reliability.** Add the reliability numbers to the section, from the [agent numbers](../../design/evaluation.md#agent-numbers) in the log: the failed action rate, the turns that hit a limit or ended with `force`, and the cost per turn. Commit: `docs: add reliability to the skill measure`.
3. **Report.** Describe the evaluation report: what `npm run evaluate` reads, and the fields of its JSON and Markdown files. Add an open question on whether a native AI could play the agent's own slot on the same seed as a reference run. Commit: `docs: design the evaluation report`.

## Done when

[evaluation.md](../../design/evaluation.md) has the skill measure, the reliability numbers, and the report, each with a `## Decisions` row, and the [evaluator](evaluator.md) step can be built from it.

## Record

- The skill measure, the reliability numbers, and the report, in [evaluation.md](../../design/evaluation.md).
