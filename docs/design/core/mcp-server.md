# MCP server

How the bridge serves its tools over MCP: one server, reached in process by the agent loop and over local HTTP by outside clients. Part of the [bridge](bridge.md).

`createServer()` in `src/mcp/server.ts` builds the server with `@modelcontextprotocol/server`, the v2 MCP SDK. The server's name is `sentient-systems`, and its version is the bridge's.

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
| A taken port warns, and the bridge runs without HTTP | The tuner connection and the logs still work, and the warning names the port to change |
