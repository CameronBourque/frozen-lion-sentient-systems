// Tests for governors.ts, against the fake game. The stash's failures are
// tested in state.test.ts, through readState.

import { beforeEach, describe, expect, test } from "vitest";
import { readGovernorTree } from "../../src/trees/governors.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type CommandResult, type FakeGame, startGame } from "../tuner/fake-game.js";

const STASH = "SentientSystems_Stash(SentientSystems_GetGovernorTree(0))";
const PIECE = "SentientSystems_PrintPiece(1)";

// The smallest governor tree the schema accepts. The schemas are checked in
// contract.test.ts.
const GOVERNOR_TREE = {
	governors: [{
		type: "GOVERNOR_THE_DEFENDER",
		name: "Victor",
		title: "The Castellan",
		description: "Military focused.",
		status: "candidate" as const,
		promotions: [{ type: "GOVERNOR_PROMOTION_REDOUBT", name: "Redoubt", description: "Defends.", level: 0, column: 1, requires: [], status: "held" as const }],
	}],
};

describe("readGovernorTree", () => {
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
		answer({ [STASH]: { output: ["1"] }, [PIECE]: { output: [json] } });
	}

	test("reads the tree through the stash from the core mod's state", async () => {
		const json = JSON.stringify(GOVERNOR_TREE);

		stash(json);

		expect(await readGovernorTree(client, 0)).toEqual({ ok: true, value: GOVERNOR_TREE, bytes: Buffer.byteLength(json) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: PIECE },
		]);
	});

	test("reads a percent sign that the core mod wrote as \\u0025, so the game's log never sees it", async () => {
		const promotion = { ...GOVERNOR_TREE.governors[0].promotions[0], description: "30% science and +15% Production" };
		const tree = { governors: [{ ...GOVERNOR_TREE.governors[0], promotions: [promotion] }] };
		const json = JSON.stringify(tree).replaceAll("%", "\\u0025");

		expect(json).not.toContain("%");
		stash(json);

		expect(await readGovernorTree(client, 0)).toEqual({ ok: true, value: tree, bytes: Buffer.byteLength(json) });
	});

	test("names the governor tree in the game's error", async () => {
		answer({ [STASH]: { luaError: "no player 0" } });

		expect(await readGovernorTree(client, 0)).toEqual({ ok: false, error: "The governor tree request failed in the game: no player 0" });
	});
});
