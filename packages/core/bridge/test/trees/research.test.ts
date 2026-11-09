// Tests for research.ts, against the fake game. The stash's failures are tested
// in state.test.ts, through readState.

import { beforeEach, describe, expect, test } from "vitest";
import { readCivicTree, readTechTree } from "../../src/trees/research.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type CommandResult, type FakeGame, startGame } from "../tuner/fake-game.js";

const STASH = "SentientSystems_Stash(SentientSystems_GetTechTree(0))";

// The smallest tree the schema accepts. The schemas are checked in
// contract.test.ts.
const TREE = {
	nodes: [{ type: "TECH_POTTERY", era: "ERA_ANCIENT", status: "researched" as const, prerequisites: [] }],
	players: [{ player: 0, researched: 1 }],
};
const JSON_TEXT = JSON.stringify(TREE);

describe("readTechTree and readCivicTree", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	// Answers each command with the result given for it. Other Lua prints
	// nothing.
	function answer(results: Record<string, CommandResult | undefined>): void {
		game.onCommand = (_stateIndex, lua) => (lua in results ? results[lua] : {});
	}

	function stash(json: string): void {
		answer({ [STASH]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [json] } });
	}

	test("reads the tree through the stash from the core mod's state", async () => {
		stash(JSON_TEXT);

		expect(await readTechTree(client, 0)).toEqual({ ok: true, value: TREE, bytes: Buffer.byteLength(JSON_TEXT) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("names the tech tree in the game's error", async () => {
		answer({ [STASH]: { luaError: "no player 0" } });

		expect(await readTechTree(client, 0)).toEqual({ ok: false, error: "The tech tree request failed in the game: no player 0" });
	});

	test("reads the civic tree with its own call", async () => {
		answer({ "SentientSystems_Stash(SentientSystems_GetCivicTree(0))": { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON_TEXT] } });

		expect(await readCivicTree(client, 0)).toEqual({ ok: true, value: TREE, bytes: Buffer.byteLength(JSON_TEXT) });
	});

	test("names the civic tree in the game's error", async () => {
		answer({ "SentientSystems_Stash(SentientSystems_GetCivicTree(0))": { luaError: "no player 0" } });

		expect(await readCivicTree(client, 0)).toEqual({ ok: false, error: "The civic tree request failed in the game: no player 0" });
	});
});
