// Tests for state.ts, against the fake game. The schemas are tested in
// contract.test.ts, against the JSON from the Lua tests.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { CORE_STATE } from "../../src/connect.js";
import { readState, type State } from "../../src/state/state.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

// The smallest state the schema accepts: every section, empty where it can be,
// with one blocker so the text has a name to cut in the middle. The schemas are
// checked in contract.test.ts.
const STATE: State = {
	blockers: { list: [{ type: "ENDTURN_BLOCKING_RESEARCH" }], units: [] },
	cities: [],
	units: [],
	tiles: [],
	proposals: [],
	scoreboard: [],
	victories: {},
	religion: {},
	diplomacy: [],
	envoys: { tokens: 0, influence: { points: 0, perTurn: 0, threshold: 0, envoys: 0 }, cityStates: [] },
	espionage: { capacity: 0, operatives: [], cities: [], history: [], captives: [] },
	greatPeople: [],
	continents: [],
	greatWorks: { slots: [], buildings: [], works: 0, spaces: 0, provides: [] },
	trade: { outgoing: [], incoming: [], tourismBonus: 0 },
	player: {
		gold: { balance: 0, perTurn: 0 },
		faith: { balance: 0, perTurn: 0 },
		science: 0,
		culture: 0,
		tourism: 0,
		resources: [],
		income: {
			gold: { total: 0 },
			faith: { total: 0 },
			science: { total: 0 },
			culture: { total: 0 },
			expenses: { total: 0, cities: 0, units: 0, deals: 0 },
			cities: [],
			unitUpkeep: [],
			deals: [],
		},
	},
	rivals: { cities: [], units: [] },
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

	// Answers the stash with the number of pieces, and each piece with its
	// text.
	function stash(pieces: string[]): void {
		answer({ [STASH]: { output: [String(pieces.length)] }, ...Object.fromEntries(pieces.map((piece, i) => [`SentientSystems_PrintPiece(${i + 1})`, { output: [piece] }])) });
	}

	// Answers each command with the result given for it. Other Lua prints
	// nothing.
	function answer(results: Record<string, CommandResult | undefined>): void {
		game.onCommand = (_stateIndex, lua) => (lua in results ? results[lua] : {});
	}

	test("reads the state in one piece from the core mod's state", async () => {
		const json = JSON.stringify(STATE);

		stash([json]);

		expect(await readState(client, 0)).toEqual({ ok: true, value: STATE, bytes: Buffer.byteLength(json) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("joins the pieces with nothing between them", async () => {
		const json = JSON.stringify(STATE);
		const cut = json.indexOf("RESEARCH") + 3;

		stash([json.slice(0, cut), json.slice(cut)]);

		const result = await readState(client, 0);

		expect(result).toEqual({ ok: true, value: STATE, bytes: Buffer.byteLength(json) });
		expect(game.commands.map(({ lua }) => lua)).toEqual([STASH, "SentientSystems_PrintPiece(1)", "SentientSystems_PrintPiece(2)"]);
	});

	test("asks for the given player's state", async () => {
		answer({ "SentientSystems_Stash(SentientSystems_GetState(3))": { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify(STATE)] } });

		expect((await readState(client, 3)).ok).toBe(true);
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
		stash([JSON.stringify({ ...STATE, cities: [{ name: 7 }], tiles: [{ x: 0, y: 0 }] })]);

		const result = await readState(client, 0);

		expect(!result.ok && result.error).toMatch(/^The core mod's state JSON doesn't match the schema: .*cities\.0\.name: .*tiles\.0\.terrain: /);
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
