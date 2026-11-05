# Opening books

An opening book is a tree of plans for the first turns of a game. The agent picks an opening from the book that fits its personality and its start, and code follows the opening through standing orders. As the agent learns more about the map and its neighbors, the opening branches. The agent leaves the book when the game goes off its plan or the book ends.

## Why

The first 30 to 60 turns of a Civ VI game repeat across games. Most starts build a scout, a slinger or a warrior, and settlers, and research the same few techs. A model that reasons through each of those turns spends tokens to make choices that are already well known. Early mistakes also cost more than late ones, because every later turn builds on the start.

A single fixed opening does not fit every start. A coastal start, a crowded start, and a civ with an early unique unit each want a different plan. A tree lets the book adapt as the agent sees more of the map.

## Shape

A book is a set of openings. Each opening is a tree of nodes. A node holds:

- the items to build, in order,
- the techs and civics to research, in order,
- unit goals, such as "scout toward the nearest unexplored land",
- branches, each with a condition and the node it leads to,
- end conditions, such as a turn number.

Steps name game items by type, such as `UNIT_SETTLER` or `TECH_POTTERY`, so they work with `GameInfo` and with modded content that keeps the base types. Steps never name a tile. A step that needs a tile, such as founding a city or placing a district, calls a [decision helper](helpers.md), such as `suggest_settle_sites`.

An example opening, in a format that is still open:

```yaml
id: fast-expansion
score:
  personality: { expansion: 3, military: 1 }
  start: { open-land-within-10: 2, rival-within-8: -2 }
build: [UNIT_SCOUT, UNIT_SLINGER, UNIT_SETTLER, UNIT_SETTLER]
research: [TECH_POTTERY, TECH_ANIMAL_HUSBANDRY]
civics: [CIVIC_CODE_OF_LAWS]
branches:
  - when: rival-within-8
    to: fast-expansion/defend-first
  - when: turn-25
    to: fast-expansion/settle-wave
end:
  turn: 60
```

Conditions come from a fixed list, as [wake triggers](standing-orders.md#wake-triggers) do. Each one is a plain check in code on the state.

## Picking an opening

A helper, `suggest_opening`, scores each opening on turn 1. The score adds two parts:

- **Personality.** Weights from the personality file, such as expansion or military, times the opening's weights for them.
- **Start.** Checks on what the agent can see on turn 1, such as a coast, a river, hills, luxuries, and open land. The civ note adds checks for its civ, such as an early unique unit that suits a rush.

The helper returns the top few openings, and the agent picks one with a `reason`. At no sweat, the helper adds noise to the scores, as [helpers.md](helpers.md#weights) describes.

A civ note can also add an opening of its own, such as a rush with an early unique unit. A modded civ with no such note uses the general openings.

## Following an opening

The current node becomes [standing orders](standing-orders.md): a build list for the capital, a research path, and unit goals. Code carries them out, and the model runs only on a wake trigger, as it does for any order.

Code checks the branch conditions each turn. When one branch matches, code takes it, and the state diff tells the agent which branch it took. When several branches match at once, the bridge wakes the model to pick one. The agent can also move to another branch or another opening at any time with a `reason`.

## Leaving the book

The agent leaves the book in any of these cases:

- The opening reaches its end condition.
- A civ declares war on the agent, or a city is under attack.
- The agent loses a city or a settler.
- The agent chooses to leave, with a `reason`.

After the agent leaves the book, its standing orders stay active until it changes or cancels them. The agent then plays without the book for the rest of the game.

## Writing and tuning books

We write the first openings by hand. Each opening is a file in the `openings/` folder of the [knowledge files](../knowledge-files.md#file-layout).

Decision records log the opening the agent picked, each branch it took, and the turn and reason it left the book. The game review metrics in `docs/design/decision-support/game-review.md*` at the end of the book, such as the number of cities and the score against the native AI on that turn, show which openings work on which starts. Those results tune the weights and the branches.

## Open questions

- What file format do openings use? The example above is a draft.
- How many openings ship at first?
- When several branches match, should code take the highest-scoring one instead of waking the model?
- How do the start checks see a map that is mostly under fog on turn 1?

## Decisions

| Decision | Reason |
| --- | --- |
| Openings are trees that branch on conditions | One fixed plan does not fit every start, and the agent learns about its start as it scouts |
| Personality weights and start checks pick the opening | Agents with different personalities open differently on the same start |
| A node runs as standing orders | Quiet opening turns cost no model call, and the agent can cancel any order |
| Steps name item types, never tiles | Tiles differ in every game, and the helpers pick tiles |
| Branch conditions come from a fixed list | Each condition is a plain check in code, with no model call |
| The agent can leave the book at any time | The book serves the agent, and an unusual start needs its own plan |
