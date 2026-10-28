// Tests for governors.ts, against the fake game. The stash's failures are tested in state.test.ts,
// through readState.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { CORE_STATE } from "../../src/connect.js";
import { readGovernorTree } from "../../src/trees/governors.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

const STASH = "SentientSystems_Stash(SentientSystems_GetGovernorTree(0))";
const PIECE = "SentientSystems_PrintPiece(1)";

// A governor tree with an appointed governor and a candidate, in the shape the core mod sends.
const GOVERNOR_TREE = {
	governors: [
		{
			type: "GOVERNOR_THE_MERCHANT",
			name: "Reyna",
			title: "The Financier",
			description: "Shrewd and fiscally knowledgeable, Reyna strengthens the economic power of a city.",
			status: "appointed" as const,
			turnsToEstablish: 5,
			loyalty: 8,
			promotions: [
				{ type: "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION", name: "Land Acquisition", description: "Acquires tiles.", level: 0, column: 1, requires: [], status: "held" as const },
				{
					type: "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER",
					name: "Harbormaster",
					description: "Double adjacency bonuses from Commercial Hubs and Harbors in the city.",
					level: 1,
					column: 0,
					requires: ["GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION"],
					status: "available" as const,
				},
			],
		},
		{
			type: "GOVERNOR_THE_DEFENDER",
			name: "Victor",
			title: "The Castellan",
			description: "Military focused.",
			status: "candidate" as const,
			turnsToEstablish: 3,
			loyalty: 8,
			promotions: [{ type: "GOVERNOR_PROMOTION_REDOUBT", name: "Redoubt", description: "Defends.", level: 0, column: 1, requires: [], status: "held" as const }],
		},
	],
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

	// Answers each command with the result given for it. Other Lua prints nothing.
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

		expect(await readGovernorTree(client, 0)).toEqual({ ok: true, tree: GOVERNOR_TREE, bytes: Buffer.byteLength(json) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: PIECE },
		]);
	});

	test("reads a percent sign that the core mod wrote as \\u0025, so the game's log never sees it", async () => {
		const promotion = { ...GOVERNOR_TREE.governors[1].promotions[0], description: "30% science and +15% Production" };
		const tree = { governors: [{ ...GOVERNOR_TREE.governors[1], promotions: [promotion] }] };
		const json = JSON.stringify(tree).replaceAll("%", "\\u0025");

		expect(json).not.toContain("%");
		stash(json);

		expect(await readGovernorTree(client, 0)).toEqual({ ok: true, tree, bytes: Buffer.byteLength(json) });
	});

	test("reads a Secret Society with no stats and a hidden promotion", async () => {
		const owls = {
			type: "GOVERNOR_OWLS_OF_MINERVA",
			name: "Owls of Minerva",
			title: "Secret Society",
			description: "A secret group of wealthy individuals.",
			status: "candidate" as const,
			secret: true as const,
			promotions: [
				{ type: "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", name: "Initiation", description: "Unlocked by sending an Envoy.", level: 0, column: 1, requires: [], status: "held" as const },
				{
					type: "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2",
					name: "???",
					description: "Not yet revealed.",
					level: 1,
					column: 1,
					requires: ["GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1"],
					status: "locked" as const,
					hidden: true as const,
				},
			],
		};
		const json = JSON.stringify({ governors: [owls] });

		stash(json);

		expect(await readGovernorTree(client, 0)).toEqual({ ok: true, tree: { governors: [owls] }, bytes: Buffer.byteLength(json) });
	});

	test("fails for a promotion status the panel doesn't use", async () => {
		const bad = { governors: [{ ...GOVERNOR_TREE.governors[1], promotions: [{ ...GOVERNOR_TREE.governors[1].promotions[0], status: "unlocked" }] }] };

		stash(JSON.stringify(bad));

		const result = await readGovernorTree(client, 0);

		expect(!result.ok && result.error).toMatch(/^The core mod's governor tree JSON doesn't match the schema: governors\.0\.promotions\.0\.status: /);
	});

	test("names the governor tree in the game's error", async () => {
		answer({ [STASH]: { luaError: "no player 0" } });

		expect(await readGovernorTree(client, 0)).toEqual({ ok: false, error: "The core mod failed to build the governor tree: no player 0" });
	});
});
