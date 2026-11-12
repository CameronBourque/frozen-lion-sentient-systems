# Game review

After a game ends, the game review finds where the agent fell behind and what it did wrong, and writes a few lessons for later games. It works from a small metrics line that the bridge writes for each player on each turn, and from the decision records. It does not grade each move.

## Why

Decision records alone are noisy. A long game holds thousands of decisions, and reading them all costs more than the game did. Most of them did not matter.

The review narrows the records to the turns that did matter, and turns them into lessons that tune the [knowledge files](../knowledge-files.md), the [helper weights](helpers.md#weights), the [opening books](opening-books.md), and the [model routing](model-routing.md) weights.

## Why not grade each move

Chess engines grade a move against the best move they can find. Civ VI has no engine that finds the best move, and the result of one move shows up only many turns later, mixed with the results of every other move. A model asked to grade each move would guess.

The review uses three things that need no grade:

- **Turning points.** Turns where the agent's numbers fell behind the other players.
- **Blunders.** Mistakes that code can find with a rule.
- **Replays.** A second run from a save, with another choice, compared on the numbers.

## Metrics

The review reads the metrics lines and the agent numbers from the log, and compares the agent with the other players through the relative measures and the targets for its sweat level. All of them are in [evaluation.md](../evaluation.md).

## Steps

The review runs these steps after the game ends.

1. **Turning points.** Code compares the agent's numbers with the other players' numbers on each turn. It lists the windows where the agent's rank or gap changed most, such as science that fell from second to sixth between turns 80 and 100.
2. **Blunders.** Code checks the game for mistakes with rules. The first rules are in the table below.
3. **Lessons.** A strong model reads the turning points, the blunders, the decision records in those windows, and the journal. It writes a few lessons. Each lesson names the situation, what the agent did, what to try instead, and the turns and records behind it.
4. **Your review.** You read the lessons and move the good ones into the knowledge files, the helper weights, or the opening books. Lessons you have not reviewed stay in a file of pending lessons.

These are the first blunder rules. The list is partial.

| Blunder | Found when |
| --- | --- |
| Lost city | The agent loses a city |
| Lost settler or builder | A rival or barbarians capture or kill one |
| Undefended loss | A unit dies with no friendly unit within 2 tiles |
| Long waste | The [end-turn check](end-turn-check.md) logs the same waste item for many turns |
| Lopsided war | The agent declares war on a civ with much more military strength |
| Stalled turn | The loop hits a limit and forces the end of a turn |

## Lessons across games

One game proves little, because luck and the start shape every result. Each pending lesson keeps a count of the games it came up in. A lesson that comes up in many games, on different starts, is worth more than one that came up once. You decide when a count is high enough to act on.

## Replays

Replays are the last part to build, because each one plays many turns again. For the largest turning points only, the bridge loads the autosave from the start of the window and plays it again with a different choice, such as a campus in place of a second settler.

Then it compares the metrics after the same number of turns. The comparison answers whether the other choice was better, on that start, without a grade.

A replay needs an autosave on every turn, as the MVP gate preset in [testing.md](../testing.md) sets, and the checkpoint IDs, so the agent's memory matches each save.

## Open questions

- Where does the file of pending lessons live, and does it move with the knowledge files when a user updates the mod?
- Should lessons ever reach the agent before you review them?

## Decisions

| Decision | Reason |
| --- | --- |
| The review finds turning points and blunders, and does not grade each move | No engine finds the best move in Civ VI, so a grade would be a guess |
| You review each lesson before it changes a knowledge file | One game proves little, and a wrong lesson would spread to every later game |
| Replays come last | Each replay plays many turns again, so it costs the most |
