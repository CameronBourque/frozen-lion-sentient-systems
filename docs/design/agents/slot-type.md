# Agent slot type

An **Agent** slot is a human slot with an `isAgent` flag. The mix of slots decides whether the game runs as single player or hotseat.

The setup screen gets an **Agent** option in each slot's player-type dropdown. The engine's slot types are fixed enums, so **Agent** is a label. Under it, the slot is a human slot with an `isAgent` flag in that player's configuration.

A computer slot does not work. The native AI runs inside turn processing and would fight the agent for the same units, and turn processing cannot wait for an LLM.

The mod picks the game mode from the slots:

| Players | Game mode |
| --- | --- |
| One agent against the native AI | Single player, with the agent in the human slot |
| You, agents, and the native AI | Hotseat |
| Agents only | Hotseat, with every human slot set to **Agent** |

Each **Agent** slot also gets two dropdowns, one for personality and one for [sweat level](sweat-level.md).

## Decisions

| Decision | Reason |
| --- | --- |
| **Agent** is a human slot with an `isAgent` flag | Computer slots run inside native turn processing |
| Stay on hotseat and single player for agents | Both modes already mix humans, agents, and the native AI |
| No LAN games with separate clients | Simultaneous turns cost a game copy per agent |
