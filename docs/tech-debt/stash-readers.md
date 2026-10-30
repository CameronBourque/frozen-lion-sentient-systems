# Stash readers

Six readers call `readStash` and only rename its `value` field, each with its own result type. Callers can use `StashResult` directly. See the [tech debt index](README.md).

## Now

`readState`, `readChoices`, `readTechTree`, `readCivicTree`, `readGovernorTree`, and `readPlacement` each return `readStash`'s result with `value` renamed, such as to `state`. Each declares a result type: `StateResult`, `ChoicesResult`, `TreeResult`, `GovernorTreeResult`, and `PlacementResult`. No other file imports those types.

The readers are in `packages/core/bridge/src/state/state.ts`, `src/choices/choices.ts`, `src/trees/research.ts`, `src/trees/governors.ts`, and `src/placement/placement.ts`.

## Proposal

1. Make each reader return `StashResult<T>` from `src/stash.ts`.
2. Delete the five result types.
3. Change the callers in `scripts/state.ts` and the tests to read `value`.

## Questions

1. Does the MCP server in [phase 1 step 9](../roadmap/phase-1/09-mcp-server.md) need each reader by name, or can it call `readStash` with the call and the schema?

## Done when

- The bridge has one result type for stash reads.
