// Tests for mcp/server.ts.

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { expect, test } from "vitest";
import packageJson from "../../package.json" with { type: "json" };
import { SERVER_NAME, createServer } from "../../src/mcp/server.js";

test("an in-process client connects and reads the bridge's name and version", async () => {
	const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
	const server = createServer();
	const client = new Client({ name: "test", version: "1.0.0" });

	await server.connect(serverSide);
	await client.connect(clientSide);

	expect(client.getServerVersion()).toMatchObject({ name: SERVER_NAME, version: packageJson.version });

	await client.close();
	await server.close();
});
