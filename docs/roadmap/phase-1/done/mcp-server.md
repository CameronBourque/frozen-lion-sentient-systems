# Phase 1: MCP server

The finished steps of [phase 1](../README.md) that serve the state, the action API, and the Civilopedia as MCP tools, and generate their reference page. The index is in [README.md](README.md).

## MCP server

Pull request: feat(core): add the MCP server.

The bridge serves 44 tools from one MCP server, built with the v2 MCP SDK. The agent loop will reach it in process, and Claude Code and the MCP Inspector reach it over local HTTP.

- **Transports.** `--mcp` serves the tools over Streamable HTTP at `http://127.0.0.1:<mcpPort>/mcp`, with 4320 as the default, and `npm run mcp` starts the bridge this way. HTTP, not stdio, keeps the game's one tuner client in the bridge you start.
- **Player.** Every tool acts for the player its server's context names, so no tool takes a player ID. Over HTTP it is the local player, asked for on each call.
- **State tools.** `get_state`, `get_choices` with an optional city, `get_placement`, `get_tech_tree`, `get_civic_tree`, `get_trade_routes`, `get_great_work_moves`, `search_civilopedia`, and `read_civilopedia` return compact JSON.

  `SentientSystems_GetCityRoutes`, `SentientSystems_GetGreatWorkMoves`, and the city filter of `SentientSystems_GetChoices` were added to the core mod for them.
- **Action tools.** 35 tools, one for each verb of the action API, go through `registerAction`. Each requires a `reason` of at most 200 characters and logs an `action` record at the `decisions` level.

  A success says the game took the request, and a failure returns its reason as a result marked `isError`.
- **No game.** While the bridge isn't connected to the game, every tool answers at once that it isn't.
- **Claude Code.** `.mcp.json` points Claude Code at the bridge, and live tests call the tools in place of probe scripts. The phase 0 gate script is gone.
- **Check.** The built executable, started with `--mcp`, listed Rome, moved a unit, and ended the turn with a `reason` on each action, from Claude Code and from the MCP Inspector. The log held each `action` record and no errors.

- How the server, its transports, and its tools work, and why, in [design/core/mcp-server.md](../../../design/core/mcp-server.md).
- `mcpPort`, in [design/core/settings.md](../../../design/core/settings.md), and the `action` record, in [design/core/logs.md](../../../design/core/logs.md).
- How live tests reach the tools, in [design/testing.md](../../../design/testing.md#live-tests).
- Four debts the step found, in [tech-debt/](../../../tech-debt/README.md): an optional `reason`, state sections, action changes, and the move refusal at a river.

## Tool reference

Pull request: ci: generate the tool reference.

`docs/reference/tools.md` lists the 44 tools with the descriptions and fields the model reads, and a workflow keeps it current on every pull request.

- **Script.** `npm run tool-reference` lists the tools from an in-process server, with no game, and writes one section per tool: its description and a table of its fields. Nested fields get their own rows, and an enum of up to 8 values lists them as its type.
- **Check.** `check-docs` skips the writing and length rules for generated pages in `docs/reference/`, and still checks their links.
- **Workflow.** One job generates the page with no token. A second job commits it with the release app token through the contents API, only when it changed, and never runs PR code.

  The [Claude Code gate](../claude-code-gate.md) makes the first live run of that commit.

- The script and the workflow, in [design/core/toolchain.md](../../../design/core/toolchain.md).
- The `docs/reference/` exception, in [rules/docs.md](../../../rules/docs.md#automated-check).
