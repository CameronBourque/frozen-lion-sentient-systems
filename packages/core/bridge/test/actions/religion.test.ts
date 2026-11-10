// Tests for religion.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { foundPantheon } from "../../src/actions/religion.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("foundPantheon", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to found the pantheon", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_FoundPantheon(0, \"BELIEF_RELIGIOUS_SETTLEMENTS\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await foundPantheon(client, 0, "BELIEF_RELIGIOUS_SETTLEMENTS")).toEqual({ ok: true });
	});

	test("returns the core mod's reason", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_FoundPantheon(0, \"BELIEF_DESERT_FOLKLORE\"))";
		const reason = "Another player has BELIEF_DESERT_FOLKLORE already. Use a type from the pantheon choice.";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] } })[lua] ?? {};

		expect(await foundPantheon(client, 0, "BELIEF_DESERT_FOLKLORE")).toEqual({ ok: false, reason });
	});
});
