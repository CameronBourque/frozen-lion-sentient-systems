# Turn loop

What an agent does on its turn: resolve the end-turn blockers, act through a small set of general tools, recover from failed actions, and end the turn within fixed limits.

## Steps

The loop starts when the bridge sees the turn-start event for an agent slot. It runs these steps until the turn passes:

1. Read the state and the list of end-turn blockers.
2. Resolve the blockers: a new tech, a pantheon, an era dedication, units that need orders, or a proposed deal.
3. Take the agent's other actions.
4. End the turn.

Plain code handles trivial cases without the LLM, such as fortifying idle units and setting scouts to auto-explore. Quick movement and quick combat stay on during agent turns.

## Tools

There is one tool per kind of decision. For example, `move_unit` moves any unit, and `unit_action(unit, action, target)` covers fortify, found city, build improvement, and pillage. Cities, research, civics, policies, diplomacy, religion, governors, great people, and the World Congress follow the same pattern. The tool set must let an agent play any strategy it chooses.

For discrete choices, the agent picks from the legal options in the state. For spatial actions, the agent gives a destination, and the game's pathfinding plans multi-turn moves.

Every action tool has a required `reason` field. See [narration-and-messaging.md](narration-and-messaging.md).

## Failure handling

When an action fails, the agent gets the reason and decides again. The loop limits retries per action, actions per turn, and time per turn. When the loop hits a limit, it ends the turn and logs a failure. One stuck turn then cannot stop a game.

## Decision records

During testing, the agent records each important decision with its reason. It adds the short-term result on the next turn and the long-term result at its next deep strategic review. The records are noisy, and that is acceptable. You review them over time and turn useful patterns into [knowledge files](../knowledge-files.md).

## Decisions

| Decision | Reason |
| --- | --- |
| One tool per kind of decision | A small set of general tools is easier for the model to use, and it still covers every action |
| Retry, action, and time limits per turn | One stuck turn cannot stop a game |
| Record decisions and their results during testing | Noisy records still show which patterns belong in knowledge files |
