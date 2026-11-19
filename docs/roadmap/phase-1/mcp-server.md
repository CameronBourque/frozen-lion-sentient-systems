# MCP server

Expose the state, the action API, and the lookup as MCP tools. Every action tool has a required `reason` field. Part of [phase 1](README.md).

## Tasks

1. **Server.** Add `src/mcp/server.ts` with the MCP SDK and no tools. The agent loop connects to it in process, through the SDK's in-memory transport.

   Add a `--mcp` flag that also serves the same tools over the SDK's Streamable HTTP transport, for Claude Code and the MCP Inspector. The bridge keeps its tuner connection and its console logs, so one bridge serves every client.

   Listen on `127.0.0.1` only, with the SDK's DNS rebinding check. Add `mcpPort` to the config file, with a fixed default. Add `npm run mcp`, which runs `npm run dev` with `--mcp`. Commit: `feat(core): add the MCP server`.
2. **State tools.** Add `get_state`, `get_choices`, `get_placement`, `get_tech_tree`, `get_civic_tree`, `search_civilopedia`, and `read_civilopedia`. `get_placement` takes a city and a district or wonder, and returns its tiles.

   `search_civilopedia` takes a query. `read_civilopedia` takes a page ID, a section ID, or both. With neither, it lists the sections.

   Write each tool's description for the model, because the [tool reference](tool-reference.md) reuses it. Commit: `feat(core): add the state and Civilopedia tools`.
3. **On-demand state tools.** Add `get_trade_routes`, which takes a city ID and returns the routes that city could start.

   Add `get_great_work_moves`, which takes a great work's index and returns the slots it can move to. Each calls its function, `SentientSystems_GetCityRoutes` or `SentientSystems_GetGreatWorkMoves`, through the stash.

   Give each a zod schema in `src/state/`, which the contract test checks against the Lua fixtures.

   Both lists are too large for the state, so they are functions of one city or one work. Write each tool's description for the model. Commit: `feat(core): add the on-demand state tools`.
4. **City filter.** Give `get_choices` an optional city ID, and `SentientSystems_GetChoices` an optional `cityID` that leaves out the other cities' entries in each choice that has one for each city. Commit: `feat(core): filter the choices by city`.
5. **Unit and end turn tools.** Add `registerAction`, the helper that every action tool goes through, and `move_unit`, `unit_action`, and `end_turn`. Tasks 6 to 16 add the other action tools through it, one tool per verb, as [turn-loop.md](../../design/agents/turn-loop.md#tools) describes.

   A success returns "The game took the request." A failed action returns its reason as a tool result marked `isError`, not as an MCP error. `unit_action` takes every order of the action API's `UnitOrder`, and `end_turn` takes `force`. Commit: `feat(core): add the unit and end turn action tools`.
6. **City tools.** Add `set_production`, `purchase`, and `purchase_tile`. `set_production` takes `queue` to add to the queue instead. Commit: `feat(core): add the city action tools`.
7. **Strike and city fate tools.** Add `city_attack`, `silo_strike`, and `decide_city`. Commit: `feat(core): add the strike and city fate action tools`.
8. **Research tools.** Add `set_research`, `set_civic`, and `set_government`. `set_research` and `set_civic` take `queue`. Commit: `feat(core): add the research and government action tools`.
9. **Policy tools.** Add `set_policies`, `unlock_policies`, and `choose_dedications`. Commit: `feat(core): add the policy and dedication action tools`.
10. **Religion tools.** Add `found_pantheon`, `found_religion`, and `add_belief`. Commit: `feat(core): add the religion action tools`.
11. **Governor tools.** Add `appoint_governor`, `promote_governor`, and `assign_governor`. Commit: `feat(core): add the governor action tools`.
12. **Great people and great work tools.** Add `recruit_great_person`, which also passes or patronizes, `move_great_work`, and `choose_artifact`. `move_great_work` takes the `cityID`, `building`, and `slot` of a move from `get_great_work_moves`.

   Commit: `feat(core): add the great people and great work action tools`.
13. **Trade route and envoy tools.** Add `start_trade_route` and `send_envoys`. Commit: `feat(core): add the trade route and envoy action tools`.
14. **Espionage tools.** Add `spy_mission`, `spy_travel`, and `choose_escape_route`. Commit: `feat(core): add the espionage action tools`.
15. **World Congress tools.** Add `vote_in_congress` and `propose_in_congress`. Commit: `feat(core): add the World Congress action tools`.
16. **Diplomacy tools.** Add `respond_to_deal`, `respond_to_session`, `declare_war`, and `propose_peace`. Commit: `feat(core): add the diplomacy action tools`.
17. **`reason` field.** Make `reason` a required string on every action tool, and log it at the decisions level with the call.

   Add it in `registerAction`, so [optional-reason.md](../../tech-debt/optional-reason.md) can make it optional in one place. Test that a call without it fails. Commit: `feat(core): require a reason on every action`.
18. **Claude Code.** Add `.mcp.json` at the repo root, which points Claude Code at the bridge's MCP URL.

   Start the bridge with `npm run mcp` before you open Claude Code. Live tests in Claude Code then call the same tools as the agent loop, in place of probe scripts. Commit: `chore(core): connect Claude Code to the MCP server`.
19. **Remove the gate script.** Delete `packages/core/bridge/scripts/gate.ts` and the `gate` script in the bridge's `package.json`. Commit: `chore(core): remove the phase 0 gate script`.

## Done when

The bridge executable, built with `npm run build:exe` and started with `--mcp`, lists cities, moves a unit, and ends the turn through the MCP Inspector, with a `reason` on each action. Claude Code does the same through `.mcp.json`.

## Record

- The MCP server and its transports, in [mcp-server.md](../../design/core/mcp-server.md), with `## Decisions` rows for the in-memory transport and for Streamable HTTP over stdio.
- `mcpPort`, in [settings.md](../../design/core/settings.md).
- How live tests reach the tools through `.mcp.json`, in [testing.md](../../design/testing.md).
- Remove the `gate.ts` mention from this phase's README.
