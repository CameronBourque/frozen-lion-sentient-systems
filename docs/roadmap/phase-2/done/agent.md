# Phase 2: agent steps

The finished steps of [phase 2](../README.md) that build the agent: its personality, sweat level, and memory. The step table's `#` column sets their order.

## Personality and sweat level

Pull request: feat(core): add the neutral personality and the balanced sweat level.

It added the neutral personality, the balanced sweat level, and the rules of play as knowledge files in `packages/core/bridge/knowledge/`, which the executable carries as Node SEA assets.

It also added `systemPrompt` and `turnMessage` in `src/agents/prompt.ts`, which build the prompt from them and the state.

The executable, copied alone to an empty folder, read the 3 files. A test builds the prompt from the shipped files and a fixed state. The executable builds its first real prompt in the [agent loop](turn-loop.md#agent-loop) step.

- Where the files live, their format, and the neutral personality are in [design/knowledge-files.md](../../../design/knowledge-files.md#file-layout).
- How the prompt is built, and why the state goes in once per turn, are in [design/agents/prompt.md](../../../design/agents/prompt.md).
- How the executable carries the files is in [design/distribution.md](../../../design/distribution.md), with the asset facts in [findings/build-tooling.md](../../../findings/build-tooling.md).
- **Random** resolving to a personality when the game starts is in [design/agents/slot-type.md](../../../design/agents/slot-type.md).

## Memory and decision records

Pull request: feat(core): add plan and journal memory.

It added each agent's memory files in `memory/player-<ID>/`, next to the config file: `plan.md`, `journal.md`, and `decisions.jsonl`. It also added the four tools that change them, `update_plan`, `add_journal_entry`, `record_decision`, and `record_result`, and their parts in the turn message.

A file the store can't read moves aside with a warning. Until checkpoint IDs exist, `startMemory` moves stale memory aside on turn 1 or an earlier turn than the memory holds.

A test runs two fake turns through the tools and checks all three files. The agent loop calls `startMemory` in the [agent loop](turn-loop.md#agent-loop) step.

- The files, their formats, unreadable files, and stale memory are in [design/memory.md](../../../design/memory.md#files-on-disk).
- The decision records and their results are in [design/agents/turn-loop/decision-records.md](../../../design/agents/turn-loop/decision-records.md).
- The memory tools and the `memory` source are in [design/core/mcp-server.md](../../../design/core/mcp-server.md).
- The plan, journal, and decision parts of the turn message are in [design/agents/prompt.md](../../../design/agents/prompt.md#two-calls).
- The `journalEntries` cap is in [design/core/settings.md](../../../design/core/settings.md).
