// Serves the MCP server over Streamable HTTP for --mcp, so Claude Code and the
// MCP Inspector share the bridge's one tuner connection.
// docs/design/core/mcp-server.md has the design.

import { createServer as createHttpServer } from "node:http";
import type { AddressInfo } from "node:net";
import { localhostHostValidation, localhostOriginValidation, toNodeHandler } from "@modelcontextprotocol/node";
import { createMcpHandler } from "@modelcontextprotocol/server";
import type { Logger } from "../log.js";
import { createServer } from "./server.js";
import type { ToolContext } from "./context.js";

// Loopback only, so no other machine can call the tools.
export const MCP_HOST = "127.0.0.1";
export const MCP_PATH = "/mcp";

export interface McpHttp {
	url: string;
	close: () => Promise<void>;
}

export function mcpUrl(port: number): string {
	return `http://${MCP_HOST}:${port}${MCP_PATH}`;
}

// Starts the HTTP server on a port, or on a free one for port 0. If the port
// can't be used, warns and returns undefined, and the bridge keeps running
// without it.
export function startMcpHttp(port: number, context: ToolContext, logger: Logger): Promise<McpHttp | undefined> {
	const onerror = (error: Error): void => logger.warn("mcp_request_failed", `An MCP request failed: ${error.message}`, { reason: error.message });
	const mcp = createMcpHandler(() => createServer(context), { onerror });
	const handle = toNodeHandler(mcp, { onerror });
	// The Host and Origin checks stop a web page from reaching the tools
	// through DNS rebinding.
	const validateHost = localhostHostValidation();
	const validateOrigin = localhostOriginValidation();
	const server = createHttpServer((req, res) => {
		if (!validateHost(req, res) || !validateOrigin(req, res)) {
			return;
		}

		if (new URL(req.url ?? "/", "http://localhost").pathname !== MCP_PATH) {
			res.writeHead(404).end();

			return;
		}

		// toNodeHandler answers its own failures with a 500 and calls onerror.
		void handle(req, res);
	});

	return new Promise((resolve) => {
		server.once("error", (error) => {
			logger.warn("mcp_failed", `Can't serve the MCP tools on port ${port}, so the bridge runs without them: ${error.message}`, { port, reason: error.message });
			resolve(undefined);
		});
		server.listen(port, MCP_HOST, () => {
			const url = mcpUrl((server.address() as AddressInfo).port);

			logger.info("mcp_started", `Serving the MCP tools at ${url}`, { url });
			resolve({
				url,
				close: async () => {
					await mcp.close();
					server.closeAllConnections();
					await new Promise((done) => server.close(done));
				},
			});
		});
	});
}
