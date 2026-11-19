// Tests for mcp/state-tools.ts and mcp/results.ts: each tool sends its call
// for the server's player, through an in-process client and the fake game.
// The readers and their schemas have their own tests.

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { beforeEach, describe, expect, test } from "vitest";
import type { PlayerSource } from "../../src/mcp/player.js";
import { NOT_CONNECTED } from "../../src/mcp/results.js";
import { createServer } from "../../src/mcp/server.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

const PLAYER_3: PlayerSource = () => Promise.resolve({ ok: true, playerID: 3 });
const TREE = { nodes: [], players: [{ player: 3, researched: 0 }] };

let game: FakeGame;
let client: TunerClient;

beforeEach(async () => {
	({ game, client } = await startGame());
});

// Connects an in-process client to a server for the player.
async function connect(player = PLAYER_3, tuner = client): Promise<Client> {
	const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
	const mcp = new Client({ name: "test", version: "1.0.0" });

	await createServer({ client: tuner, player }).connect(serverSide);
	await mcp.connect(clientSide);

	return mcp;
}

// Answers the stash of each call in the table with its value as JSON. Other
// Lua prints nothing.
function answer(values: Record<string, unknown>): void {
	let next: unknown;

	game.onCommand = (_stateIndex, lua) => {
		const call = /^SentientSystems_Stash\((.*)\)$/s.exec(lua)?.[1];

		if (call !== undefined && call in values) {
			next = values[call];

			return { output: ["1"] };
		}

		return lua === "SentientSystems_PrintPiece(1)" ? { output: [JSON.stringify(next)] } : {};
	};
}

// The tool's text, and whether it is an error.
async function call(mcp: Client, name: string, args: Record<string, unknown> = {}): Promise<{ text: string; isError: boolean }> {
	const result = await mcp.callTool({ name, arguments: args });
	const [content] = result.content as { type: string; text: string }[];

	return { text: content.text, isError: result.isError === true };
}

test("the server lists the seven tools, each with a description", async () => {
	const { tools } = await (await connect()).listTools();

	expect(tools.map((tool) => tool.name)).toEqual([
		"get_state", "get_choices", "get_placement", "get_tech_tree", "get_civic_tree", "search_civilopedia", "read_civilopedia",
	]);
	expect(tools.every((tool) => (tool.description ?? "").length > 50)).toBe(true);
});

describe("the player tools", () => {
	test("get_tech_tree and get_civic_tree return compact JSON for the server's player", async () => {
		answer({ "SentientSystems_GetTechTree(3)": TREE, "SentientSystems_GetCivicTree(3)": TREE });

		const mcp = await connect();

		expect(await call(mcp, "get_tech_tree")).toEqual({ text: JSON.stringify(TREE), isError: false });
		expect(await call(mcp, "get_civic_tree")).toEqual({ text: JSON.stringify(TREE), isError: false });
	});

	test("get_state and get_choices send their calls for the player, and a bad read is an error result", async () => {
		answer({ "SentientSystems_GetState(3)": {}, "SentientSystems_GetChoices(3)": {} });

		const mcp = await connect();

		expect(await call(mcp, "get_state")).toMatchObject({ text: expect.stringContaining("state JSON doesn't match") as unknown, isError: true });
		expect(await call(mcp, "get_choices")).toMatchObject({ text: expect.stringContaining("choices JSON doesn't match") as unknown, isError: true });
	});

	test("get_placement passes the city and the type", async () => {
		const placement = { tiles: [{ x: 1, y: 2, adjacency: { science: 2 } }], purchaseTiles: [] };

		answer({ "SentientSystems_GetPlacement(3, 65536, \"DISTRICT_CAMPUS\")": placement });

		expect(await call(await connect(), "get_placement", { cityID: 65536, type: "DISTRICT_CAMPUS" })).toEqual({ text: JSON.stringify(placement), isError: false });
	});

	test("a tool with no player returns the source's error and sends nothing", async () => {
		const mcp = await connect(() => Promise.resolve({ ok: false, error: "No game is loaded" }));

		expect(await call(mcp, "get_state")).toEqual({ text: "No game is loaded", isError: true });
		expect(game.commands).toEqual([]);
	});
});

test("every tool answers at once when the bridge isn't connected to the game", async () => {
	const mcp = await connect(PLAYER_3, { isConnected: false } as TunerClient);

	for (const [name, args] of [["get_state", {}], ["search_civilopedia", { query: "x" }], ["read_civilopedia", {}]] as const) {
		expect(await call(mcp, name, args)).toEqual({ text: NOT_CONNECTED, isError: true });
	}
});

describe("the Civilopedia tools", () => {
	const PAGE = { sectionID: "UNITS", pageID: "UNIT_SETTLER", title: "Settler" };
	const SECTION = { sectionID: "UNITS", title: "Units", groups: [] };
	const SECTIONS = { sections: [{ sectionID: "UNITS", title: "Units", pageCount: 1 }] };

	beforeEach(() => {
		answer({
			"SentientSystems_Lookup(\"settler\")": { results: [{ ...PAGE }] },
			"SentientSystems_LookupPage(\"INTRO\", \"UNITS\")": PAGE,
			"SentientSystems_LookupPage(\"UNIT_SETTLER\")": PAGE,
			"SentientSystems_LookupSection(\"UNITS\")": SECTION,
			"SentientSystems_LookupSections()": SECTIONS,
		});
	});

	test("search_civilopedia searches for the query", async () => {
		expect(await call(await connect(), "search_civilopedia", { query: "settler" })).toEqual({ text: JSON.stringify({ results: [PAGE] }), isError: false });
	});

	test("read_civilopedia reads a page, a page in a section, a section, or the sections", async () => {
		const mcp = await connect();

		expect((await call(mcp, "read_civilopedia", { pageID: "UNIT_SETTLER" })).text).toBe(JSON.stringify(PAGE));
		expect((await call(mcp, "read_civilopedia", { pageID: "INTRO", sectionID: "UNITS" })).text).toBe(JSON.stringify(PAGE));
		expect((await call(mcp, "read_civilopedia", { sectionID: "UNITS" })).text).toBe(JSON.stringify(SECTION));
		expect((await call(mcp, "read_civilopedia")).text).toBe(JSON.stringify(SECTIONS));
	});

	test("a missing argument is an error result", async () => {
		expect(await call(await connect(), "search_civilopedia")).toMatchObject({ isError: true });
	});
});
