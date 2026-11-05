# Decision helpers

A decision helper is bridge code that reads the game state and returns a short, ranked list of options for one kind of decision, each with a score and a one-line reason. The agent calls helpers as tools and still makes every choice.

## Why helpers

An agent that reasons over the raw state for each decision spends many tokens, and models are weak at spatial and numeric choices such as where to settle or which tile gets a district. Code makes those choices well and at almost no cost. A helper turns a large part of the state into a few lines the model can weigh.

Helpers extend the plain code in [turn-loop.md](../agents/turn-loop.md#steps). Plain code acts on trivial cases without the model. A helper never acts. It ranks options, and the model picks one and writes the `reason`.

## Shape

Each helper is one MCP tool named `suggest_<decision>`, such as `suggest_settle_sites`. A helper returns:

- the options, best first, five by default,
- for each option, the target, a score from 0 to 100, the factors behind the score with their numbers, and a one-line reason,
- warnings for what the helper could not see, such as tiles hidden by fog.

An example result from `suggest_settle_sites`:

```json
{
	"options": [
		{
			"tile": [14, 22],
			"score": 81,
			"factors": { "food": 9, "production": 6, "freshWater": true, "luxuries": 2, "distanceToCapital": 5 },
			"reason": "River tile with two new luxuries and a hill for defense"
		}
	],
	"warnings": ["3 candidate tiles are under fog"]
}
```

Every helper follows these rules:

- **Read-only.** A helper never calls the action API.
- **Pure functions.** A helper takes the serialized state and game facts and returns a result, so its tests run without the game.
- **The game's own numbers first.** Where the game already computes a value, such as district adjacency, pathfinding, trade route yields, or a combat preview, a core mod function returns the raw numbers and the helper ranks them. Each of these game calls needs a [finding](../../findings/README.md) before code depends on it.
- **No hard-coded game facts.** Yields, costs, and bonuses come from `GameInfo`, so modded civs, units, and buildings work.
- **Fall back on missing data.** A helper with partial data returns fewer options and a warning. It does not fail the tool call.

## Weights

A helper's score is a weighted sum of its factors. Each helper has default weights. A personality file and a sweat level file can override them. A warmonger weights strategic resources and chokepoints higher when it picks a settle site, and a builder weights district adjacency higher. Different weights keep two agents from playing the same game off the same helper.

At no sweat, the helper can add random noise to the scores. [sweat-level.md](../agents/sweat-level.md) notes that models default to reasonable play, so noise in the options is one way to make no sweat play loosely.

## Helpers and knowledge files

Helpers and [knowledge files](../knowledge-files.md) split the work. A helper does the arithmetic. A concept guide says when to call the helper, how to read its result, and what the helper cannot judge. For example, the expansion guide tells the agent to call `suggest_settle_sites`, and then to decide for itself whether to settle toward a rival to claim land. Moving the arithmetic into code keeps the guides short.

Decision records log the helper's options and the rank of the option the agent chose. Over time the records show which helpers the agent ignores, and whether ignoring them won or lost. That data tunes the default weights and the guides.

## Candidate helpers

These helpers are candidates, grouped by how much judgment their scoring needs. The list is partial.

| Helper | Decision | Judgment |
| --- | --- | --- |
| `suggest_settle_sites` | Where to found the next city | Low. Yields, water, resources, and spacing |
| `suggest_district_tiles` | Which tile gets a district, counting future districts | Low. Adjacency from the game |
| `suggest_improvements` | Which tile a builder improves next | Low. Yield gain for each charge |
| `suggest_research_path` | The shortest route to a target tech or civic, with cheap eurekas and inspirations | Low. A graph search over the trees |
| `suggest_trade_routes` | The best trade route destination | Low. Yields from the game |
| `suggest_purchases` | What to buy with gold or faith | Low. Turns saved for each unit of cost |
| `suggest_policies` | Which policy cards fit the current goals | Medium |
| `suggest_production` | What each city builds next | Medium |
| `suggest_victory` | Which victory to pursue, from the scoreboard, civ traits, the map, and rivals' progress | Medium. Runs at the deep strategic review |
| `assess_threats` | Enemy units near each city, defense against likely attacks, and loyalty pressure | Medium |
| `assess_rivals` | Who is close to which victory, and who is likely to attack | Medium |
| `suggest_attacks` | Attacks with their predicted damage, and safe tiles for wounded units | High. Moving several units in a war is the hardest part of the game for an agent |

## Build order

We build a helper when decision records show agents losing on that decision. The [smoke test](../../roadmap/phase-1/smoke-test.md) and the [MVP gate](../../roadmap/phase-1/mvp-gate.md) give the first records. The low-judgment helpers come first among the decisions that fail, because they are mostly arithmetic on state the serializer already produces.

## Open questions

- What format do personality and sweat level files use for weights?
- How do we measure whether a helper helps? One candidate is a pair of test games from one preset, with and without the helper, compared on score and cost.
- Should some decisions hide the helper from the agent, so it keeps reasoning for itself and does not always take the first option?
- Can the advisors mod use the same helpers? Advisors are read-only, so a helper's result is already advice. See [advisors.md](../advisors.md).

## Decisions

| Decision | Reason |
| --- | --- |
| Helpers rank options and never act | The agent keeps the choice and writes the `reason`, so personality and narration still work |
| Helpers are code, not subagents | Code is cheaper and steadier than a model for arithmetic. [knowledge-files.md](../knowledge-files.md#file-layout) rules out subagents |
| Ranking runs in the bridge, raw numbers come from the core mod | TypeScript ranking is testable without the game, and the game's own numbers stay correct with mods |
| Personality and sweat level files set the weights | Agents with different personalities make different choices from the same helper |
| Build a helper after records show a failing decision | Records show where agents fail, so we don't build helpers they don't need |
