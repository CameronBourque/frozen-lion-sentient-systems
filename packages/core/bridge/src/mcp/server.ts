// The bridge's MCP server. The agent loop connects to it in process, and
// --mcp serves it over HTTP (src/mcp/http.ts). docs/design/core/mcp-server.md
// has the design.

import { McpServer } from "@modelcontextprotocol/server";
import packageJson from "../../package.json" with { type: "json" };
import { registerStateTools, type ToolContext } from "./state-tools.js";

export const SERVER_NAME = "sentient-systems";

// The HTTP handler builds a server for each request, so a server holds no
// state of its own. The context's player is the one every tool acts for.
export function createServer(context: ToolContext): McpServer {
	const server = new McpServer({ name: SERVER_NAME, version: packageJson.version });

	registerStateTools(server, context);

	return server;
}
