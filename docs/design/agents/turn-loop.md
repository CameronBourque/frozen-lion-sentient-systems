# Turn loop

What an agent does on its turn: resolve the end-turn blockers, act through a small set of general tools, recover from failed actions, and end the turn within fixed limits.

## Steps

The loop starts when the bridge sees the turn-start event for an agent slot. It runs these steps until the turn passes:

1. Read the state and the list of end-turn blockers.
2. Resolve the blockers: a new tech, a pantheon, an era dedication, units that need orders, or a proposed deal.
3. Take the agent's other actions.
4. End the turn.

Plain code handles trivial cases without the LLM, such as fortifying idle units and setting scouts to auto-explore. Quick movement and quick combat stay on during agent turns. [Standing orders](../decision-support/standing-orders.md) let plain code play whole quiet turns without the model.

## Tools

There is one tool per kind of decision. For example, `move_unit` moves any unit, and `unit_action(unit, action, target)` covers fortify, found city, build improvement, and pillage.

Cities, research, civics, policies, diplomacy, religion, governors, great people, and the World Congress follow the same pattern. The tool set must let an agent play any strategy it chooses.

For discrete choices, the agent picks from the legal options that `get_choices` returns. For spatial actions, the agent gives a destination, and the game's pathfinding plans multi-turn moves.

Every action tool has a required `reason` field. See [narration-and-messaging.md](narration-and-messaging.md).

## Failure handling

When an action fails, the agent gets the reason and decides again. The loop limits retries per action, actions per turn, and time per turn. When the loop hits a limit, it ends the turn and logs a failure. One stuck turn then cannot stop a game.

## Stopping

Every model call costs money, so you can stop the agent at any moment, and spending limits stop it for you. A run is one start of the bridge.

The bridge stops a run in three ways:

- **Stop key.** Press Ctrl+C in the bridge's console. The bridge aborts the model call in progress, waits for the Lua command in progress, logs `stopped`, and exits. It sends no end turn, so the game waits on the agent's turn. A second Ctrl+C exits at once.
- **Turn count.** `--turns <n>` stops the bridge the same way after the agent ends its n-th turn. Live tests use it to play a fixed number of turns.
- **Spending limits.** `limits.costPerTurn` and `limits.costPerRun` in the [config file](../core/settings.md) cap the cost of model calls in dollars, from the price table in `models.yaml`. A turn that reaches its limit ends like a turn that hits any other limit. A run that reaches its limit stops as the stop key does.

To resume, start the bridge again. [Resync on connect](../core/bridge.md) prints `AGENT_TURN` for the active turn, and the agent reads the state, which already holds the actions it took before the stop.

The smoke test sets the defaults for the spending limits from its measured cost per turn.

## Decision records

During testing, the agent records each important decision with its reason. It adds the short-term result on the next turn and the long-term result at its next deep strategic review.

The records are noisy, and that is acceptable. You review them over time and turn useful patterns into [knowledge files](../knowledge-files.md).

## Decisions

| Decision | Reason |
| --- | --- |
| One tool per kind of decision | A small set of general tools is easier for the model to use, and it still covers every action |
| Retry, action, and time limits per turn | One stuck turn cannot stop a game |
| The stop key aborts the model call and sends no end turn | Stopping costs nothing more, and the turn resumes from the state when the bridge starts again |
| The run spending limit counts one start of the bridge, not one game | A game outlives restarts, so a total per game needs stored totals. Each call's cost is already in the log |
| Spending limits are in dollars, not tokens | Users pay in dollars, and the model tiers cost different amounts per token |
| Record decisions and their results during testing | Noisy records still show which patterns belong in knowledge files |
