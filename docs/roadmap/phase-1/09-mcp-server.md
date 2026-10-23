# Step 9: MCP server

Expose the state, the action API, and the lookup as MCP tools. Every action tool has a required `reason` field. Part of [phase 1](README.md).

## Tasks

1. **Server.** Add `src/mcp/server.ts` with the MCP SDK and no tools. The agent loop connects to it in process, through the SDK's in-memory transport. Add `npm run mcp`, which serves the same tools over stdio for the MCP Inspector. Commit: `feat(core): add the MCP server`.
2. **State tools.** Add `get_state` and `lookup`. Write each tool's description for the model, because the tool reference in step 10 reuses it. Commit: `feat(core): add the state and lookup tools`.
3. **Action tools.** Add one tool per kind of decision, as [turn-loop.md](../../design/agents/turn-loop.md#tools) describes: `move_unit`, `unit_action`, `set_production`, `set_research`, `set_civic`, `set_policies`, one tool for each other blocker, and `end_turn`. A failed action returns its reason as the tool result, not as an MCP error. Commit: `feat(core): add the action tools`.
4. **`reason` field.** Make `reason` a required string on every action tool, and log it at the decisions level with the call. Test that a call without it fails. Commit: `feat(core): require a reason on every action`.
5. **Remove the gate script.** Delete `packages/core/bridge/scripts/gate.ts` and the `gate` script in the bridge's `package.json`. Commit: `chore(core): remove the phase 0 gate script`.

## Done when

The bridge executable, built with `npm run build:exe`, lists cities, moves a unit, and ends the turn through the MCP Inspector, with a `reason` on each action.

## Record

- The MCP server and the transport, in [bridge.md](../../design/core/bridge.md), with a `## Decisions` row for the in-memory transport.
- Remove the `gate.ts` mention from this phase's README.
