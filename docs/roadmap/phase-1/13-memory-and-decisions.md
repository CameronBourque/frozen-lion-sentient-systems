# Step 13: Memory and decision records

Add the plan and journal memory files, the tools that change them, and decision records. Phase 1 has no relationships file and no snapshots. This step doesn't need the game. Part of [phase 1](README.md).

## Tasks

1. **Store.** Add `src/memory/store.ts`, which reads and writes `plan.md` and `journal.md` in one folder per agent, next to the config file. Each file starts with a schema version, as [versioning.md](../../design/versioning.md#bump-rules) requires. Commit: `feat(core): add the memory store`.
2. **Tools.** Add `update_plan`, which overwrites the plan, and `add_journal_entry`, which appends an entry with the turn number. See [memory.md](../../design/memory.md#memory-files). Commit: `feat(core): add the plan and journal tools`.
3. **Prompt.** Add the plan and the newest journal entries to the turn message from step 12. Cap the journal at a number of entries set in the config file. Commit: `feat(core): add memory to the agent prompt`.
4. **Decision records.** Add `record_decision`, which appends `{ turn, decision, reason }` to `decisions.jsonl`. On the next turn, the prompt lists the last turn's records and asks for each short-term result, and `record_result` writes it. See [turn-loop.md](../../design/agents/turn-loop.md#decision-records). Commit: `feat(core): add decision records`.

## Done when

A test runs two fake turns through the tools. After it, `plan.md` holds the second plan, `journal.md` holds both entries, and `decisions.jsonl` holds one record with its short-term result.

## Record

The file names, the folder, and the tools, in [memory.md](../../design/memory.md) and [turn-loop.md](../../design/agents/turn-loop.md#decision-records).
