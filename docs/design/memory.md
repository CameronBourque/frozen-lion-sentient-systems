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

## Files on disk

`src/memory/store.ts` in the bridge reads and writes the files in `memory/player-<ID>/`, next to the config file. The caller passes the folder, so a snapshot can be restored by pointing the store at it.

| File | Format | Tools |
| --- | --- | --- |
| `plan.md` | Markdown after YAML front matter | `update_plan` |
| `journal.md` | Markdown after YAML front matter, one `## Turn N` section per entry | `add_journal_entry` |
| `decisions.jsonl` | One JSON [decision record](agents/turn-loop.md#decision-records) per line | `record_decision`, `record_result` |

Phase 2 has no relationships file. Each file carries `schemaVersion`, as [versioning.md](versioning.md#bump-rules) requires: the front matter holds it for the Markdown files, and each line holds it for `decisions.jsonl`.

A missing file reads as empty. A file with no front matter, a line that doesn't parse, or another schema version moves to `<name>.unreadable-<time>` with a warning, and reads as empty. A later write then can't replace it.

The [MCP server](core/mcp-server.md) gets the folder from its context's `memory` function, and the [prompt](agents/prompt.md#two-calls) shows the files' contents each turn.

## Stale memory

Until checkpoint IDs exist, `startMemory` checks the memory on the agent's first turn after the bridge starts. Memory with an entry or record from a later turn, or any memory on turn 1, belongs to another game or a later save.

The bridge then moves the folder to `player-<ID>.old-<time>`, warns, and starts the agent with empty memory. Nothing is deleted.

A restart of the bridge during turn 1 also moves that turn's memory aside. [Phase 3](../roadmap/phase-3/README.md) replaces this rule with [checkpoint IDs](#checkpoint-ids).

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
| All of an agent's memory in one folder | A snapshot is a copy of the folder, and a restore points the store at the copy |
| The plan and journal are Markdown with YAML front matter | You read and edit them while you tune agents, and the front matter holds the schema version |
| A file the store can't read moves aside instead of being replaced | A hand edit or a newer bridge's file isn't lost, and the agent still plays |
| Stale memory moves aside on turn 1 or an earlier turn, until checkpoint IDs exist | A new game or an older save otherwise hands the agent memories of turns that no longer exist |
