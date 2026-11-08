// Tests for placement.ts, against the fake game. The stash's failures are
// tested in state.test.ts, through readState.

import { beforeEach, describe, expect, test } from "vitest";
import { readPlacement } from "../../src/placement/placement.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type CommandResult, type FakeGame, startGame } from "../tuner/fake-game.js";

const STASH = "SentientSystems_Stash(SentientSystems_GetPlacement(0, 65536, \"DISTRICT_CAMPUS\"))";

// The smallest placement the schema accepts. The schemas are checked in
// contract.test.ts.
const PLACEMENT = { tiles: [{ x: 17, y: 13 }], purchaseTiles: [] };
const JSON_TEXT = JSON.stringify(PLACEMENT);

describe("readPlacement", () => {
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

	test("reads a district's tiles through the stash from the core mod's state", async () => {
		answer({ [STASH]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON_TEXT] } });

		expect(await readPlacement(client, 0, 65536, "DISTRICT_CAMPUS")).toEqual({ ok: true, value: PLACEMENT, bytes: Buffer.byteLength(JSON_TEXT) });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("fails without a command for a type name that isn't one", async () => {
		const typeName = "DISTRICT_CAMPUS\") os.exit() --";

		expect(await readPlacement(client, 0, 65536, typeName)).toEqual({
			ok: false,
			error: `${JSON.stringify(typeName)} isn't a type name, such as DISTRICT_CAMPUS`,
		});
		expect(game.commands).toEqual([]);
	});

	test("names the placement in the game's error", async () => {
		answer({ [STASH]: { luaError: "BUILDING_GRANARY isn't a district or a wonder" } });

		expect(await readPlacement(client, 0, 65536, "DISTRICT_CAMPUS")).toEqual({
			ok: false,
			error: "The placement request failed in the game: BUILDING_GRANARY isn't a district or a wonder",
		});
	});
});
