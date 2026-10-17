# Sweat level

Sweat level sets how hard an agent pushes toward victory. It is a mindset in the prompt and the knowledge files, and it does not choose the model. Each **Agent** slot has its own level, so one game can mix levels.

| Level | How the agent plays |
| --- | --- |
| No sweat | Plays on whims. Builds what sounds good, pursues several victories loosely, ignores whether a choice is optimal, and uses no exploits |
| Balanced | Keeps pace with the leaders. Watches the scoreboard and catches up when it falls behind, but does not race to the front |
| Super sweat | Uses every advantage. Picks the best strategy for its position, pushes one victory hard, and takes any edge the rules allow |

These descriptions are a starting point. Tuning comes from logs, decision records, and playtests. No sweat is the hardest level to get right, because models default to reasonable play.

The level files live in `sweat/`. See [knowledge-files.md](../knowledge-files.md).

## AI difficulty

The base **Difficulty** setting keeps its job. It sets the native AI's bonuses. Agents are human slots, so the setting affects only the native AI. We plan to relabel the setting **AI Difficulty** with a text change.

## Decisions

| Decision | Reason |
| --- | --- |
| Sweat level is a mindset, not a model choice | It describes how competitively an agent plays |
| Sweat level per agent, separate from difficulty | Agents in one game can play at different levels |
| Relabel **Difficulty** as **AI Difficulty**, keep its job | It still sets native AI bonuses |
