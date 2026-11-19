// Tests for mcp/server.ts.

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { expect, test } from "vitest";
import packageJson from "../../package.json" with { type: "json" };
import { SERVER_NAME, createServer } from "../../src/mcp/server.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { connectTools } from "./tools.js";

test("an in-process client connects and reads the bridge's name and version", async () => {
	const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
	const server = createServer({ client: {} as TunerClient, player: () => Promise.resolve({ ok: false, error: "No game" }) });
	const client = new Client({ name: "test", version: "1.0.0" });

	await server.connect(serverSide);
	await client.connect(clientSide);

	expect(client.getServerVersion()).toMatchObject({ name: SERVER_NAME, version: packageJson.version });

	await client.close();
	await server.close();
});

test("the server lists every tool, each with a description", async () => {
	const { tools } = await (await connectTools({} as TunerClient)).listTools();

	expect(tools.map((tool) => tool.name)).toEqual([
		"get_state", "get_choices", "get_placement", "get_tech_tree", "get_civic_tree", "get_trade_routes", "get_great_work_moves",
		"search_civilopedia", "read_civilopedia",
		"move_unit", "unit_action",
		"set_production", "purchase", "purchase_tile", "city_attack", "silo_strike", "decide_city",
		"set_research", "set_civic", "set_policies", "unlock_policies", "set_government", "choose_dedications",
		"found_pantheon", "found_religion", "add_belief",
		"appoint_governor", "promote_governor", "assign_governor",
		"end_turn",
	]);
	expect(tools.every((tool) => (tool.description ?? "").length > 50)).toBe(true);
});
