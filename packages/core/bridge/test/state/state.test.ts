// Tests for state.ts, against the fake game. Each section's schema has its own tests beside this file.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { CORE_STATE } from "../../src/connect.js";
import { readState, type State } from "../../src/state/state.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

// A state with one of each thing, in the shape the core mod sends.
const STATE: State = {
	blockers: { list: [{ type: "ENDTURN_BLOCKING_RESEARCH", choice: "techs" }], units: [196608] },
	cities: [{
		id: 65536,
		name: "Rome",
		x: 17,
		y: 14,
		population: 3,
		amenities: { have: 2, need: 2, mood: "HAPPINESS_CONTENT" },
		defense: { strength: 13, garrison: { value: 200, max: 200 } },
		districts: [{
			type: "DISTRICT_CITY_CENTER",
			x: 17,
			y: 14,
			complete: true,
			pillaged: false,
			buildings: [{ type: "BUILDING_MONUMENT", pillaged: false }],
		}],
		growth: { foodSurplus: 3, housing: 6, turnsUntilGrowth: 2 },
		loyalty: { value: 100, max: 100, perTurn: 21 },
		production: { type: "UNIT_SLINGER", turnsLeft: 2 },
		yields: { food: 9, production: 6, gold: 8, science: 3.5, culture: 3.8, faith: 0 },
	}],
	units: [{
		id: 196608,
		type: "UNIT_SCOUT",
		x: 24,
		y: 15,
		moves: { left: 3, max: 3 },
		health: { value: 100, max: 100 },
		experience: { points: 0, nextLevel: 15 },
		promotions: [],
		availablePromotions: [],
	}],
	tiles: [
		{ x: 17, y: 14, terrain: "TERRAIN_PLAINS", owner: 0, district: "DISTRICT_CITY_CENTER", route: "ROUTE_ANCIENT_ROAD", visible: true },
		{ x: 29, y: 17, terrain: "TERRAIN_GRASS", resource: "RESOURCE_CATTLE", owner: 1, visible: false },
	],
	rivals: {
		cities: [{
			owner: 1,
			id: 65536,
			name: "Râ-Kedet",
			x: 30,
			y: 18,
			population: 2,
			capital: true,
			defense: { strength: 13, garrison: { value: 200, max: 200 } },
		}],
		units: [{ owner: 1, id: 131073, type: "UNIT_WARRIOR", x: 25, y: 14, health: { value: 100, max: 100 } }],
	},
};

const STASH = "SentientSystems_Stash(SentientSystems_GetState(0))";

describe("readState", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		game = await FakeGame.start();
		game.states = [{ index: 0, name: "Main State" }, { index: 130, name: CORE_STATE }];
		// A short timeout, so the timeout test takes milliseconds.
		client = new TunerClient({ port: game.port, retryDelayMs: 10, timeoutMs: 100 });
		client.connect();
		await once(client, "connected");
	});

	afterEach(async () => {
		client.close();
		await game.close();
	});

	// Answers the stash with the number of pieces, and each piece with its text.
	function stash(pieces: string[]): void {
		answer({ [STASH]: { output: [String(pieces.length)] }, ...Object.fromEntries(pieces.map((piece, i) => [`SentientSystems_PrintPiece(${i + 1})`, { output: [piece] }])) });
	}

	// Answers each command with the result given for it. Other Lua prints nothing.
	function answer(results: Record<string, CommandResult | undefined>): void {
		game.onCommand = (_stateIndex, lua) => (lua in results ? results[lua] : {});
	}

	test("reads the state in one piece from the core mod's state", async () => {
		const json = JSON.stringify(STATE);

		stash([json]);

		expect(await readState(client, 0)).toEqual({ ok: true, state: STATE, bytes: Buffer.byteLength(json) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("joins the pieces with nothing between them", async () => {
		const json = JSON.stringify(STATE);
		const cut = json.indexOf("Rome") + 2;

		stash([json.slice(0, cut), json.slice(cut)]);

		const result = await readState(client, 0);

		expect(result).toEqual({ ok: true, state: STATE, bytes: Buffer.byteLength(json) });
		expect(game.commands.map(({ lua }) => lua)).toEqual([STASH, "SentientSystems_PrintPiece(1)", "SentientSystems_PrintPiece(2)"]);
	});

	test("asks for the given player's state", async () => {
		answer({ "SentientSystems_Stash(SentientSystems_GetState(3))": { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify(STATE)] } });

		expect((await readState(client, 3)).ok).toBe(true);
	});

	test("drops a field that the schema doesn't know", async () => {
		stash([JSON.stringify({ ...STATE, scoreboard: [] })]);

		const result = await readState(client, 0);

		expect(result.ok && "scoreboard" in result.state).toBe(false);
	});

	test("fails when the stash doesn't print a piece count", async () => {
		answer({ [STASH]: { output: ["nope"] } });

		expect(await readState(client, 0)).toEqual({ ok: false, error: "Reading the state failed: SentientSystems_Stash printed [\"nope\"], not a piece count" });
	});

	test("fails when the stash prints more than one line", async () => {
		answer({ [STASH]: { output: ["2", "3"] } });

		expect((await readState(client, 0)).ok).toBe(false);
	});

	test("fails with the JSON error when the pieces aren't valid JSON", async () => {
		stash(["{\"cities\":"]);

		const result = await readState(client, 0);

		expect(result.ok).toBe(false);
		expect(!result.ok && result.error).toMatch(/^The core mod's state JSON isn't valid: /);
	});

	test("fails with each field that doesn't match the schema", async () => {
		stash([JSON.stringify({ ...STATE, cities: [{ ...STATE.cities[0], name: 7 }], tiles: [{ x: 0, y: 0 }] })]);

		const result = await readState(client, 0);

		expect(!result.ok && result.error).toMatch(/^The core mod's state JSON doesn't match the schema: cities\.0\.name: .*; tiles\.0\.terrain: .*; tiles\.0\.visible: /);
	});

	test("fails when the state isn't an object", async () => {
		stash(["[]"]);

		expect(await readState(client, 0)).toEqual({ ok: false, error: "The core mod's state JSON doesn't match the schema: the state: Invalid input: expected object, received array" });
	});

	test("fails with the game's error when the core mod can't build the state", async () => {
		answer({ [STASH]: { luaError: "no player 0\nstack traceback:\n\t[C]: in function 'error'" } });

		expect(await readState(client, 0)).toEqual({ ok: false, error: "The core mod failed to build the state: no player 0" });
	});

	test("fails when the core mod's state isn't loaded", async () => {
		game.states = [{ index: 0, name: "Main State" }];

		const result = await readState(client, 0);

		expect(!result.ok && result.error).toMatch(/isn't loaded\. Turn on Sentient Systems Core in Additional Content, then load a game$/);
	});

	test("fails when the game doesn't answer in time", async () => {
		answer({ [STASH]: undefined });

		expect(await readState(client, 0)).toEqual({ ok: false, error: "The game didn't answer the state request in time, maybe because a game is loading" });
	});
});
