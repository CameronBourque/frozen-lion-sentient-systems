# MCP server

How the bridge serves its tools over MCP: one server, reached in process by the agent loop and over local HTTP by outside clients. Part of the [bridge](bridge.md).

`createServer(context)` in `src/mcp/server.ts` builds the server with `@modelcontextprotocol/server`, the v2 MCP SDK. The server's name is `sentient-systems`, and its version is the bridge's. The context holds the tuner client and the player source.

- **Player.** Every tool acts for the player that the context's `player` function returns. No tool takes a player ID, so a model can't read or act for another civ.

  Over HTTP, `localPlayer(client)` in `src/mcp/player.ts` asks the game for `Game.GetLocalPlayer()` on each call, so a load of another save needs nothing more.

  In single player the agent plays the human slot, as [slot-type.md](../agents/slot-type.md) says. For agents in computer slots, the agent loop builds one in-process server per agent, each with a source that returns that agent's player.
- **State tools.** `src/mcp/state-tools.ts` registers `get_state`, `get_choices`, `get_placement`, `get_tech_tree`, `get_civic_tree`, `get_trade_routes`, `get_great_work_moves`, `search_civilopedia`, and `read_civilopedia`.

  `get_choices` takes an optional `cityID`, which lists only that city in `production` and `purchases`.

  `get_trade_routes` and `get_great_work_moves` read one city's routes or one work's moves, which are too large for the state. Their schemas are in `src/state/city-routes.ts` and `src/state/great-work-moves.ts`.

  `read_civilopedia` opens a page by `pageID`, lists a section's pages by `sectionID`, or lists the sections with neither.
- **Results.** `src/mcp/results.ts` returns a read as compact JSON text. A failed read, or a missing player, is a result marked `isError` with the error text, not a protocol error, so the model reads why.

  While the bridge isn't connected to the game, every tool answers at once that it isn't. A request would otherwise wait for the game's handshake, and the tool would never answer.

  Each tool's description names the fields whose meaning the JSON doesn't show, because the schemas' `.describe()` notes don't reach the model.
- **Action tools.** There is one tool per verb of the [action API](mod/actions/README.md), such as `move_unit`, `set_production`, and `end_turn`.

  Each area has its own file, such as `src/mcp/unit-tools.ts`, `src/mcp/city-tools.ts`, and `src/mcp/turn-tools.ts`. Each goes through `registerAction` in `src/mcp/action.ts`, so a field that every action has is added in one place.

  Every action tool requires `reason`, one sentence of at most 200 characters, first in its schema so a model gives it before the action's fields.

  `registerAction` adds it, and logs each action at the `decisions` level as an `action` record with the tool, the player, the reason, the fields, and the result.

  A success returns "The game took the request.", because an ok result means the game took the request, not that it is done. The model reads the state for the effect. A failed action returns its reason as a result marked `isError`.

  `unit_action` takes every order of the action API's `UnitOrder`, and its description lists them from one table, which TypeScript checks against the type. The core mod checks that an order has the fields it needs.

  An action with an optional tile, such as `unit_action` and `set_production`, refuses `x` without `y` through `optionalTile`.
- **In process.** The agent loop connects to the server through the SDK's `InMemoryTransport`, so the loop needs no port.
- **Over HTTP.** With `--mcp`, `src/mcp/http.ts` also serves the server over Streamable HTTP at `http://127.0.0.1:<mcpPort>/mcp`, for Claude Code and the MCP Inspector. `npm run mcp` starts the bridge this way, and `mcpPort` is in the [config file](settings.md).

  The SDK's handler builds a server for each request, so a server holds no state between calls. The bridge keeps its one tuner connection and its console logs, and every client shares them.
- **Local only.** The HTTP server listens on `127.0.0.1`, so no other machine reaches it. The Host and Origin checks from `@modelcontextprotocol/node` refuse any other host name or web origin with a `403`, so a web page can't reach the tools through DNS rebinding. Any path but `/mcp` gets a `404`.
- **Taken port.** If the port is taken, the bridge logs `mcp_failed` as a warning and runs without the HTTP server. A failed request logs `mcp_request_failed`.

## Decisions

| Decision | Reason |
| --- | --- |
| The agent loop reaches the server through the in-memory transport | The loop runs in the bridge, so it needs no port, and it calls the same tools as an outside client |
| Outside clients reach the server over Streamable HTTP, not stdio | The game takes one tuner client at a time ([protocol.md](../../findings/tuner/protocol.md)). A stdio server would be a second bridge that Claude Code starts and stops. Over HTTP, the bridge you start keeps the tuner connection and its console logs |
| The v2 MCP SDK, with its Node adapter | The v2 server package depends only on `zod`. The adapter turns `node:http` requests into the web requests the SDK reads, and has the localhost Host and Origin checks |
| The server, not each tool, holds the player | A model can't name another player, and the calls cost no tokens for a player ID. An agent per computer slot gets its own server with the same tools |
| Two Civilopedia tools: `search_civilopedia` and `read_civilopedia` | One tool with four modes chosen by its fields lets a model mix them, such as a query with a page ID. Search and open-by-ID are two ideas a model tells apart |
| Results are compact JSON text, with field notes in the descriptions | An `outputSchema` would carry the notes, but a client may not show it to the model, and the state's schema would add several KB to each turn. The Claude Code gate shows which notes are missing |
| One action tool per verb, with set and queue in one tool | Each tool's schema holds only its own fields, so a model can't mix the fields of two actions. The tools cost more tokens in the tool list than one tool per area would |
| `reason` is first in every action's schema, with a 200 character cap | A model writes the fields in schema order, so it gives the reason before it picks the action's fields. The narrator panel shows one sentence, as [narration-and-messaging.md](../agents/narration-and-messaging.md) says |
| An action's success says the game took the request | The game finishes some actions after the call returns, such as a move. [state-sections.md](../../tech-debt/state-sections.md) and [action-changes.md](../../tech-debt/action-changes.md) cut the cost of reading the effect |
| A taken port warns, and the bridge runs without HTTP | The tuner connection and the logs still work, and the warning names the port to change |
