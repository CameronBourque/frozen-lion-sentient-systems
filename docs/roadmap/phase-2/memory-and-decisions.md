# Memory and decision records

Add the plan and journal memory files, the tools that change them, and decision records. Phase 2 has no relationships file and no snapshots. This step doesn't need the game. Part of [phase 2](README.md).

## Tasks

1. **Store.** Add `src/memory/store.ts`, which reads and writes `plan.md` and `journal.md` in `memory/player-<ID>/`, next to the config file. The caller passes the folder, so phase 3 can point the store at a restored snapshot.

   Each file starts with a schema version in YAML front matter, as [versioning.md](../../design/versioning.md#bump-rules) requires.

   A missing file reads as empty. A file with no front matter or an unknown schema version moves to `<name>.unreadable-<time>`, reads as empty, and gives a warning, so a later write can't replace it. Commit: `feat(core): add the memory store`.
2. **Stale memory.** When the agent's first turn after the bridge starts is turn 1, or is lower than the newest turn in its journal, move the agent's folder to `player-<ID>.old-<time>` beside it, log a warning, and start with empty memory.

   A new game or an older save then can't hand the agent memory of turns that no longer exist.

   This covers the gap until the checkpoint IDs in [phase 3](../phase-3/README.md) replace it. Commit: `feat(core): move stale memory aside`.
3. **Tools.** Add `update_plan`, which overwrites the plan, and `add_journal_entry`, which appends an entry with the turn number. See [memory.md](../../design/memory.md#memory-files). Commit: `feat(core): add the plan and journal tools`.
4. **Prompt.** Add the plan and the newest journal entries to `turnMessage`, which [prompt.md](../../design/agents/prompt.md) describes. Cap the journal at a number of entries set in the config file. Commit: `feat(core): add memory to the agent prompt`.
5. **Decision records.** Add `record_decision`, which appends `{ turn, decision, reason }` to `decisions.jsonl`.

   On the next turn, the prompt lists the last turn's records and asks for each short-term result, and `record_result` writes it. See [turn-loop.md](../../design/agents/turn-loop.md#decision-records). Commit: `feat(core): add decision records`.

## Done when

A test runs two fake turns through the tools. After it, `plan.md` holds the second plan, `journal.md` holds both entries, and `decisions.jsonl` holds one record with its short-term result.

A test then starts the agent at turn 1. After it, the old folder sits beside the new one under an `.old-<time>` name, and the new folder is empty.

## Record

The file names, the folder, the tools, and the stale memory rule, in [memory.md](../../design/memory.md) and [turn-loop.md](../../design/agents/turn-loop.md#decision-records).
