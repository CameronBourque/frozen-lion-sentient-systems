# Agent memory and save branching

The bridge owns agent memory, not the model. Each agent has three private memory files, and a checkpoint ID stored in each save lets the bridge restore the right memory after a reload or a branch.

## Memory files

The model keeps nothing between turns. At the start of each turn, the bridge loads the agent's memory into the prompt. The agent changes memory only through tools such as `update_plan` and `add_journal_entry`.

| File | Holds | How it changes |
| --- | --- | --- |
| Plan | The current strategy, a few lines | The agent overwrites it when the strategy changes |
| Relationships | One section per rival: grudges, promises, trust | The agent edits the section for that rival |
| Journal | A log of what happened | The agent appends entries. Deep strategic reviews compact old entries into a summary |

Each agent's files are private. No agent can read another agent's memory.

## Checkpoint IDs

A reload can give an agent memories of turns that no longer exist. Branching saves make this worse. You can reload turn 50, play to turn 80 again, and then want the first turn 80 back. Two saves then share a turn number but hold different games.

The checkpoint ID fixes both cases:

1. After each agent turn, a gameplay script writes a new UUID into a game property.
2. The bridge snapshots every agent's memory under that UUID.
3. Every save made after that point carries the UUID inside it. This covers manual saves, autosaves, and renamed files.
4. When a game loads, the bridge reads the UUID and restores that snapshot.

The save holds only the UUID, one short string. The memory itself stays in files the bridge manages, so you can read it while you tune agents. Snapshots are small text files, so the bridge keeps all of them and needs no pruning.

Whether the property API works from the needed Lua state is still open. See [findings/game-api.md](../findings/game-api.md#game-properties-for-checkpoint-ids).

## Decisions

| Decision | Reason |
| --- | --- |
| The bridge owns memory, and the agent edits it through tools | The model keeps nothing between turns |
| Checkpoint UUID in the save, memory in bridge files | Handles reloads and branches without size limits |
