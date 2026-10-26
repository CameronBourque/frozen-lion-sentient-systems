// Tests for choices.ts, against the fake game. The stash's failures are tested in state.test.ts,
// through readState.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { CORE_STATE } from "../../src/connect.js";
import { readChoices } from "../../src/choices/choices.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

const STASH = "SentientSystems_Stash(SentientSystems_GetChoices(0))";

// Choices with one city that can train one unit, build nothing else, and buy one unit with gold, and
// one tech to research, in the shape the core mod sends.
const CHOICES = {
	production: [{ city: 65536, name: "Rome", units: [{ type: "UNIT_SCOUT", cost: 15, turns: 2 }], buildings: [], districts: [], wonders: [], projects: [] }],
	purchases: [{ city: 65536, name: "Rome", gold: { units: [{ type: "UNIT_SCOUT", cost: 60 }], buildings: [], districts: [], tiles: [] }, faith: { units: [], buildings: [], districts: [] } }],
	techs: [{ type: "TECH_MINING", cost: 12, turns: 1, unlocks: ["IMPROVEMENT_MINE"] }],
	civics: [],
	government: { type: "GOVERNMENT_CHIEFDOM", slots: [{ slot: 0, type: "SLOT_MILITARY" }] },
};
const JSON_TEXT = JSON.stringify(CHOICES);

describe("readChoices", () => {
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

	// Answers each command with the result given for it. Other Lua prints nothing.
	function answer(results: Record<string, CommandResult | undefined>): void {
		game.onCommand = (_stateIndex, lua) => (lua in results ? results[lua] : {});
	}

	// Answers the stash with one piece that holds json.
	function stash(json: string): void {
		answer({ [STASH]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [json] } });
	}

	test("reads the choices through the stash from the core mod's state", async () => {
		stash(JSON_TEXT);

		expect(await readChoices(client, 0)).toEqual({ ok: true, choices: CHOICES, bytes: Buffer.byteLength(JSON_TEXT) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("drops a choice that the schema doesn't know", async () => {
		stash(JSON.stringify({ ...CHOICES, pantheon: [] }));

		const result = await readChoices(client, 0);

		expect(result.ok && "pantheon" in result.choices).toBe(false);
	});

	test("asks for the given player's choices", async () => {
		answer({ "SentientSystems_Stash(SentientSystems_GetChoices(3))": { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON_TEXT] } });

		expect((await readChoices(client, 3)).ok).toBe(true);
	});

	test("fails when the choices are a list", async () => {
		stash("[]");

		expect(await readChoices(client, 0)).toEqual({ ok: false, error: "The core mod's choices JSON doesn't match the schema: the choices: Invalid input: expected object, received array" });
	});

	test("names the choices in the game's error", async () => {
		answer({ [STASH]: { luaError: "no player 0\nstack traceback:\n\t[C]: in function 'error'" } });

		expect(await readChoices(client, 0)).toEqual({ ok: false, error: "The core mod failed to build the choices: no player 0" });
	});
});
