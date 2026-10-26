// Tests for trees.ts, against the fake game. The stash's failures are tested in state.test.ts,
// through readState.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { CORE_STATE } from "../../src/connect.js";
import { readTechTree } from "../../src/trees/trees.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

const STASH = "SentientSystems_Stash(SentientSystems_GetTechTree(0))";

// A tree with a researched node, a ready one, and an unrevealed one, in the shape the core mod sends.
const TREE = {
	nodes: [
		{ type: "TECH_POTTERY", era: "ERA_ANCIENT", status: "researched" as const, cost: 25, prerequisites: [], unlocks: ["BUILDING_GRANARY"] },
		{
			type: "TECH_IRRIGATION",
			era: "ERA_ANCIENT",
			status: "ready" as const,
			cost: 50,
			turns: 8,
			prerequisites: ["TECH_POTTERY"],
			boost: { percent: 40, trigger: "Farm a resource.", triggered: false },
			unlocks: ["IMPROVEMENT_PLANTATION"],
			description: "Allows clearing of Marsh.",
			recommended: true as const,
		},
		{ type: "?1", era: "ERA_CLASSICAL", status: "blocked" as const, turns: 20, prerequisites: ["TECH_IRRIGATION"] },
	],
	players: [{ player: 0, researched: 1, era: "ERA_ANCIENT" }, { player: 1, researched: 0 }],
};
const JSON_TEXT = JSON.stringify(TREE);

describe("readTechTree", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		game = await FakeGame.start();
		game.states = [{ index: 0, name: "Main State" }, { index: 130, name: CORE_STATE }];
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

	test("reads the tree through the stash from the core mod's state", async () => {
		stash(JSON_TEXT);

		expect(await readTechTree(client, 0)).toEqual({ ok: true, tree: TREE, bytes: Buffer.byteLength(JSON_TEXT) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("fails for a status the screen doesn't use", async () => {
		stash(JSON.stringify({ ...TREE, nodes: [{ ...TREE.nodes[0], status: "unknown" }] }));

		const result = await readTechTree(client, 0);

		expect(!result.ok && result.error).toMatch(/^The core mod's tech tree JSON doesn't match the schema: nodes\.0\.status: /);
	});

	test("fails for a player without a researched count", async () => {
		stash(JSON.stringify({ ...TREE, players: [{ player: 0 }] }));

		expect((await readTechTree(client, 0)).ok).toBe(false);
	});

	test("names the tech tree in the game's error", async () => {
		answer({ [STASH]: { luaError: "no player 0" } });

		expect(await readTechTree(client, 0)).toEqual({ ok: false, error: "The core mod failed to build the tech tree: no player 0" });
	});
});
