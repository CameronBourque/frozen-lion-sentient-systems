# Evaluation

How we measure an agent's game: the numbers the bridge records, the relative measures that account for the stage of the game, and the targets for each sweat level. The [game review](decision-support/game-review.md) and the [scenario tests](testing.md#scenario-tests) use these numbers.

## Record now, judge later

The bridge records raw numbers during a game and judges nothing. The game review judges them after the game ends. A new target or measure then applies to old games without playing them again, so the MVP gate game stays a baseline for later phases.

## Metrics line

After each agent turn, the bridge writes one metrics line for each living major player to `metrics.jsonl`, next to the game's [log file](core/logs.md). A line holds these numbers:

- the turn, the era, and the checkpoint ID of the turn,
- the score and its 7 categories, as the Score tab shows them,
- science, culture, and faith per turn, and gold per turn and the gold balance,
- production and food per turn, summed over the player's cities,
- favor and favor per turn, with Gathering Storm,
- military strength,
- the number of cities, the total population, and the number of techs and civics researched,
- era score, and the age the player is in: dark, normal, golden, or heroic,
- progress toward each victory, as the [victories](../findings/state/victories.md) section of the state reads it.

Each line is a few hundred bytes, so a full game with eight players stays a few megabytes. Most numbers come from the same calls as the [scoreboard](../findings/state/scoreboard.md) and the victories section.

The scoreboard gives the leader panel's numbers only for players the agent has met, so the metrics line needs a core mod call of its own that reads them for every player.

The metrics include players the agent has not met. The agent never reads the metrics file during the game, so the file leaks nothing to the agent's play.

The checkpoint ID lets the review follow only the lines of the branch that finished the game, because turns repeat after a reload. Phase 1 has no checkpoint IDs, so its lines carry the turn only.

## Agent numbers

The bridge's log already holds the numbers about the agent itself, so the metrics line doesn't repeat them. The review reads these from the log for each agent turn:

- the cost and the tokens of the model calls,
- the number of actions and of failed actions,
- whether the turn hit a limit or a [spending limit](agents/turn-loop.md#stopping), and whether it ended with `force`,
- the waste that the [end-turn check](decision-support/end-turn-check.md) found, such as idle units or unspent gold.

These numbers show whether a change made the agent cheaper or more reliable. The metrics line shows whether it played better.

## Relative measures

Every player in a game is in the same stage on a given turn. A number compared with the other players' numbers on the same turn accounts for the stage, and a fixed target for each turn breaks when the map size, speed, or player count changes. The review turns each number into these measures:

- **Rank.** The agent's place among the living major players.
- **Ratio to the median.** The agent's number over the median player's number.
- **Ratio to the leader.** The agent's number over the highest number. It is 1 when the agent leads.
- **Lead.** When the agent leads, its number over the second player's number.
- **Share.** The agent's part of the total over all players, such as its share of all science.

The review sums the measures up for each era: the median rank over the era's turns, and each ratio on the era's last turn. Eras mark the stages of a game on any game speed.

The native AI's bonuses at higher difficulties skew every relative measure. The MVP gate preset uses Prince. The targets below assume a difficulty that gives the native AI no bonus.

## Targets

Each sweat level has its own target band over the same measures. A sweat level is judged by its distance from its band, not by how high its numbers are. A balanced agent far ahead of every rival misses its target.

These targets are a starting point. When testing finds better markers or better bands, replace them here.

| Sweat level | On target | Off target |
| --- | --- | --- |
| No sweat | Progress toward at least two victories is above the median player's. The agent stays out of last place in score for all but one era and loses no city it founded | Progress in one victory far above the rest, or play that matches a super sweat agent's numbers |
| Balanced | Score rank in the top half, and a score ratio to the leader of at least 0.85 at the end of each era from the Classical era on | A ratio to the leader below 0.85, or a lead over the second player above 1.25 |
| Super sweat | Score rank 1 by the end of the Industrial era, and rank 1 in its chosen victory's progress from then on | Rank 2 or lower after the Industrial era, or progress spread over several victories |

A super sweat agent's chosen victory is the one its plan names. If its plan names none, it is the victory with the agent's highest progress.

The no sweat targets measure spread, not strength, because a no sweat agent plays on whims. The floor in its row only checks that it still plays a real game.

## Open questions

- Which number stands for progress toward each victory? The victories section of the state has a number for each, and question 1 of [victories.md](../findings/state/victories.md#questions) asks whether it rises as the screen's rings fill.
- How do the targets change at difficulties where the native AI has bonuses? The agent's own earlier games on the same preset may be a better comparison there.

## Decisions

| Decision | Reason |
| --- | --- |
| The bridge records raw numbers and the review judges them after the game | A new target or measure applies to old games without playing them again |
| The bridge writes a metrics line for each player on each turn | The lines are small, and they show where the agent fell behind without the full state |
| The metrics include players the agent has not met | The agent never reads the file during the game, and the review needs every player to rank the agent |
| Each line carries a checkpoint ID | After a reload, the review follows the branch that finished the game |
| The agent numbers come from the log, not the metrics line | The log already holds them for each turn |
| Measures compare the agent with the other players on the same turn | Every player on one turn is in the same stage, and fixed targets break when the settings change |
| Each sweat level has its own target band | A balanced agent that races ahead misses its sweat level as much as one that falls behind |
| The targets are a starting point that testing replaces | They come from reasoning, not from games |
