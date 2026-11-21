# Governor tree

The bridge reads the governor tree, but no MCP tool serves it, so the model never sees it. Serve it as a tool, or delete the reader and its core mod call.

## Now

- `readGovernorTree` in `packages/core/bridge/src/trees/governors.ts` reads `SentientSystems_GetGovernorTree(playerID)` from `Scripts/Trees/SentientSystemsCore_TreesGovernors.lua`. [bridge.md](../design/core/bridge.md) and [trees.md](../design/core/mod/trees.md) describe both.
- Only `test/trees/governors.test.ts` and `test/contract.test.ts` call it. `registerStateTools` in `src/mcp/state-tools.ts` serves `get_tech_tree` and `get_civic_tree`, and has no governor tree tool.
- `get_choices` has a `governors` key, from `GOVERNORS_CHOICE` in `src/choices/governors.ts`, with the appointments, promotions, and assignments the Governors panel offers now.
- The reader is 53 lines, its test 71, and the core mod file 105, plus its Lua test.

## Proposal

Add `get_governor_tree` beside `get_tech_tree`, if a model needs the promotions it can't take yet to plan a governor. Otherwise delete the bridge reader, its test, its contract row, the core mod file and its Lua test, and the docs that describe them.

## Questions

- Does a model plan governors better with the whole tree than with the promotions `get_choices` offers now?
- Would advisors use the tree, as the Governors panel's details panel shows it to a human?

## Done when

Either a `get_governor_tree` tool returns the tree and the tool reference lists it, or no code or doc names `SentientSystems_GetGovernorTree`.
