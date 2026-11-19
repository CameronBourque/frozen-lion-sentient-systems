// Tests for mcp/http.ts.

import { createServer as createHttpServer, request } from "node:http";
import type { AddressInfo } from "node:net";
import { Client, StreamableHTTPClientTransport } from "@modelcontextprotocol/client";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { Logger } from "../../src/log.js";
import { MCP_HOST, type McpHttp, mcpUrl, startMcpHttp } from "../../src/mcp/http.js";
import { SERVER_NAME } from "../../src/mcp/server.js";
import type { ToolContext } from "../../src/mcp/context.js";
import type { TunerClient } from "../../src/tuner/client.js";

const logger = new Logger("debug");
// No test here calls a tool, so the context needs no game.
const context: ToolContext = { client: {} as TunerClient, player: () => Promise.resolve({ ok: false, error: "No game" }), logger };

beforeEach(() => {
	vi.spyOn(console, "log").mockImplementation(() => {});
	vi.spyOn(console, "warn").mockImplementation(() => {});
});

afterEach(() => {
	vi.restoreAllMocks();
});

test("mcpUrl is on the loopback address", () => {
	expect(mcpUrl(4320)).toBe("http://127.0.0.1:4320/mcp");
});

describe("startMcpHttp", () => {
	let http: McpHttp | undefined;

	beforeEach(async () => {
		http = await startMcpHttp(0, context);
	});

	afterEach(async () => {
		await http?.close();
	});

	test("serves the MCP server to a client, and logs its URL", async () => {
		const client = new Client({ name: "test", version: "1.0.0" });

		await client.connect(new StreamableHTTPClientTransport(new URL(http!.url)));

		expect(client.getServerVersion()).toMatchObject({ name: SERVER_NAME });
		expect(console.log).toHaveBeenCalledWith(expect.stringContaining(http!.url));

		await client.close();
	});

	test("refuses a Host that isn't the local machine", async () => {
		// fetch sets Host from the URL, but node:http lets a test set it.
		const status = await new Promise((done) => {
			request(http!.url, { method: "POST", headers: { host: "evil.example" } }, (response) => {
				response.resume();
				done(response.statusCode);
			}).end();
		});

		expect(status).toBe(403);
	});

	test("refuses an Origin from another site", async () => {
		const response = await fetch(http!.url, { method: "POST", headers: { origin: "https://evil.example" } });

		expect(response.status).toBe(403);
	});

	test("answers any other path with 404", async () => {
		const response = await fetch(http!.url.replace("/mcp", "/other"));

		expect(response.status).toBe(404);
	});
});

test("warns and returns undefined when the port is taken", async () => {
	const taken = createHttpServer();

	await new Promise<void>((done) => taken.listen(0, MCP_HOST, done));

	const port = (taken.address() as AddressInfo).port;

	await expect(startMcpHttp(port, context)).resolves.toBeUndefined();
	expect(console.warn).toHaveBeenCalledWith(expect.stringContaining(`port ${port}`));

	await new Promise((done) => taken.close(done));
});
