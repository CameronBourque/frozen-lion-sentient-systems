# Stash readers

Six readers call `readStash` and only rename its `value` field, each with its own result type. Callers can use `StashResult` directly. See the [tech debt index](README.md).

## Now

`readState`, `readChoices`, `readTechTree`, `readCivicTree`, `readGovernorTree`, and `readPlacement` each return `readStash`'s result with `value` renamed, such as to `state`. Each declares a result type: `StateResult`, `ChoicesResult`, `TreeResult`, `GovernorTreeResult`, and `PlacementResult`. No other file imports those types.

The readers are in `packages/core/bridge/src/state/state.ts`, `src/choices/choices.ts`, `src/trees/research.ts`, `src/trees/governors.ts`, and `src/placement/placement.ts`. Their callers are `scripts/state.ts` and each reader's test.

## Proposal

Keep each reader and its name, and have it return `readStash`'s `StashResult<T>` as it comes. Delete the five result types. Callers read `value` in place of the renamed field.

## Questions

1. Does the MCP server in [phase 1 step 9](../roadmap/phase-1/09-mcp-server.md) need each reader by name, or can it call `readStash` with the call and the schema? Answered: by name. Each state tool in step 9 maps to one reader, and `readPlacement` checks its type name before it sends a command, so the readers stay and only their result changes.

## Tasks

Each task changes one reader file with its callers and its test, so each commit passes the type check by itself.

1. **State and choices.** Make `readState` and `readChoices` return `StashResult`, and delete `StateResult` and `ChoicesResult`. Read `value` in `scripts/state.ts`, `test/state/state.test.ts`, and `test/choices/choices.test.ts`. Commit: `refactor(core): return the stash result from the state and choices readers`.
2. **Trees.** Make `readTechTree`, `readCivicTree`, and `readGovernorTree` return `StashResult`, and delete `TreeResult` and `GovernorTreeResult`. Read `value` in `scripts/state.ts`, `test/trees/research.test.ts`, and `test/trees/governors.test.ts`. Commit: `refactor(core): return the stash result from the tree readers`.
3. **Placement.** Make `readPlacement` return `StashResult`, and delete `PlacementResult`. Read `value` in `test/placement/placement.test.ts`. Commit: `refactor(core): return the stash result from the placement reader`.

## Done when

- The bridge has one result type for stash reads.
