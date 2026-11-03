// Tests for governors.ts, against the fake game. The stash's failures are
// tested in state.test.ts, through readState.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { CORE_STATE } from "../../src/connect.js";
import { readGovernorTree } from "../../src/trees/governors.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

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

	// Answers each command with the result given for it. Other Lua prints
	// nothing.
	function answer(results: Record<string, CommandResult | undefined>): void {
		game.onCommand = (_stateIndex, lua) => (lua in results ? results[lua] : {});
	}

	// Answers the stash with one piece that holds json.
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

		expect(await readGovernorTree(client, 0)).toEqual({ ok: false, error: "The core mod failed to build the governor tree: no player 0" });
	});
});
