# Model routing

Model routing picks a model tier for each model turn. Code scores how significant the turn is from the wake triggers that fired and the decisions waiting.

The agent can also ask for a stronger model during its turn, within a budget. Cheap models play the routine turns, and strong models play the turns that decide the game.

## Why

The strong models cost many times more than the light ones for each token. Most model turns in a game are routine, such as picking the next build after an order finishes.

A few turns decide the game, such as a war declaration, a choice of government, or the founding beliefs of a religion. One model for every turn either costs too much or plays the hard turns badly.

Neither code nor the agent can judge significance alone:

- **Code alone** catches sudden events, such as a war declaration, but misses slow problems, such as a rival that has pulled ahead in science for 20 turns.
- **The agent alone** misjudges, because a light model does not know which turns are hard for it. Without a limit, an agent may also ask for the strong model on every turn.

So code sets the tier at the start of the turn, and the agent can raise it within a budget.

## Tiers

Each tier is an operation in `models.yaml`, the model table in the [knowledge files](../knowledge-files.md#layers). The table maps each tier and provider to a model.

| Tier | Plays |
| --- | --- |
| Light | Routine turns, such as a finished order or a growth in a city |
| Standard | Most turns that need a choice, and every turn with no score |
| Strong | Turns that decide the game, and the deep strategic review |

Every tier uses the same prompt, personality, memory, and tools. The bridge owns memory, as [memory.md](../memory.md) describes, so a change of model between turns loses nothing.

## Significance score

At the start of each model turn, the bridge scores the turn from three sources:

- **Wake triggers.** Each [wake trigger](standing-orders.md#wake-triggers) has a weight. A war declaration weighs more than an order that finished.
- **Decisions waiting.** Permanent choices weigh the most, such as founding beliefs, a change of government, an era dedication, or a World Congress vote.
- **The scoreboard.** A rival close to a victory, or the agent falling far behind, adds weight.

Thresholds map the score to a tier. Some decisions always get the strong tier, whatever the score, because the agent cannot undo them. The list of these decisions and the first weights are open.

The score runs in the bridge, in TypeScript, over the state, the triggers, and the end-turn blockers. It is a pure function, like the [helpers](helpers.md#shape).

## Escalation

During its turn, the agent can call `escalate` with a `reason`. The bridge then runs the rest of the turn with the next tier up, and it passes the turn's messages so far to the new model. A tier never drops during a turn.

Escalation has a budget, such as a number of escalations every 10 turns. When the budget is spent, `escalate` returns that as its result, and the turn goes on with the same model. The sweat level sets the budget, so a super sweat agent can escalate more often than a no sweat agent.

## Cost

A change of model starts a new prompt cache, so the first call after a change costs more. Routing therefore picks the tier once at the start of the turn and changes it only on escalation.

[risks.md](../../risks.md) considers a spending limit in the settings. If the settings get one, routing drops the strong tier to standard when a game nears the limit, and logs a warning.

If a tier's model fails, such as on a provider outage after retries, the turn falls back to the next tier down, and the bridge logs a warning.

## Tuning

The bridge logs each model turn's score, the triggers behind it, the tier, any escalation with its reason, and the cost. Decision records add the result. Over time the logs show these patterns:

- Escalations that changed the agent's choice point at triggers that need more weight.
- Strong turns that made routine choices point at weights that are too high.
- Light turns followed by a blunder point at a threshold that is too low.

## Open questions

- Which decisions always get the strong tier?
- What are the first weights and thresholds?
- How large is the escalation budget at each sweat level?
- Should the spending limit drop the standard tier to light too, when the limit is close?

## Decisions

| Decision | Reason |
| --- | --- |
| Code scores the turn, and the agent can escalate | Code catches sudden events, and the agent catches slow problems that code misses |
| Escalation has a budget | Without a limit, an agent may escalate on every turn |
| The tier is set once at the start of the turn, and only escalation raises it | Each change of model starts a new prompt cache |
| Permanent decisions always get the strong tier | The agent cannot undo them |
| Each tier is an operation in `models.yaml` | The model table already maps operations to models for each provider |
| A failed model falls back to the next tier down | A provider outage should slow the agent, not stop the game |
