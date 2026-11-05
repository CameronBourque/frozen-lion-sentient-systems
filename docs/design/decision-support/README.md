# Decision support

Code and formats that narrow an agent's choices and cut its token use. The agent still makes every choice. These parts give it fewer, better options and less text to read.

| File | Covers |
| --- | --- |
| [helpers.md](helpers.md) | Decision helpers: bridge tools that rank options for one kind of decision |
| [standing-orders.md](standing-orders.md) | Standing orders that plain code runs between model turns, wake triggers, and the state diff |
| [end-turn-check.md](end-turn-check.md) | The check for blockers and unused resources when the agent calls `end_turn` |
| [opening-books.md](opening-books.md) | Opening books: branching plans for the first turns, picked by personality and start |
| [model-routing.md](model-routing.md) | Model routing: the model tier for each turn, the significance score, and escalation |
