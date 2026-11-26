// Tests for mcp/in-process.ts.

import { McpServer } from "@modelcontextprotocol/server";
import { expect, test } from "vitest";
import { z } from "zod";
import packageJson from "../../package.json" with { type: "json" };
import { CLIENT_NAME, callTool, connectClient, toolDefinitions } from "../../src/mcp/in-process.js";
import { createServer } from "../../src/mcp/server.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { PLAYER_3, QUIET } from "./tools.js";

// Listing the tools calls none of them, so the tuner is never used.
function bridgeServer(): McpServer {
	return createServer({ client: {} as TunerClient, player: PLAYER_3, memory: () => "", logger: QUIET });
}

test("the server sees the agent client's name and the bridge's version", async () => {
	const server = bridgeServer();
	const client = await connectClient(server);

	expect(server.server.getClientVersion()).toEqual({ name: CLIENT_NAME, version: packageJson.version });

	await client.close();
});

test("closing the client closes the server's side", async () => {
	const server = bridgeServer();
	const client = await connectClient(server);

	await client.close();

	expect(server.isConnected()).toBe(false);
});

test("each of the server's tools becomes a definition with its description and input schema", async () => {
	const client = await connectClient(bridgeServer());
	const { tools } = await client.listTools();
	const definitions = await toolDefinitions(client);

	expect(definitions.map(({ name }) => name)).toEqual(tools.map(({ name }) => name));
	expect(definitions.map(({ description }) => description)).toEqual(tools.map(({ description }) => description));
	expect(definitions.find(({ name }) => name === "end_turn")?.inputSchema).toMatchObject({ type: "object", required: ["reason"] });

	await client.close();
});

test("a tool with no description gets an empty one", async () => {
	const server = new McpServer({ name: "bare", version: "1.0.0" });

	server.registerTool("bare", { inputSchema: z.object({ x: z.number() }) }, () => ({ content: [] }));

	const client = await connectClient(server);

	expect(await toolDefinitions(client)).toEqual([{ name: "bare", description: "", inputSchema: expect.objectContaining({ type: "object", required: ["x"] }) as unknown }]);

	await client.close();
});

test("a call to a tool the server doesn't have fails with the reason", async () => {
	const client = await connectClient(bridgeServer());

	expect(await callTool(client, "build_wonder", {})).toEqual({ text: expect.stringContaining("build_wonder") as unknown, isError: true });

	await client.close();
});

test("a call after the connection closes fails with the reason, instead of throwing", async () => {
	const client = await connectClient(bridgeServer());

	await client.close();

	expect(await callTool(client, "end_turn", {})).toMatchObject({ isError: true });
});

test("a result's text blocks join, one per line, and other blocks drop", async () => {
	const server = new McpServer({ name: "two", version: "1.0.0" });

	server.registerTool("two", {}, () => ({ content: [{ type: "text", text: "First." }, { type: "image", data: "", mimeType: "image/png" }, { type: "text", text: "Second." }] }));

	const client = await connectClient(server);

	expect(await callTool(client, "two", {})).toEqual({ text: "First.\nSecond.", isError: false });

	await client.close();
});
