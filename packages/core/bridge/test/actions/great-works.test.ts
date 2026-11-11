// Tests for great-works.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { moveGreatWork } from "../../src/actions/great-works.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("moveGreatWork", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to move the work to the slot", async () => {
		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_MoveGreatWork(0, 1203, 2, \"BUILDING_MUSEUM_ART\", 1))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[lua] ?? {};

		expect(await moveGreatWork(client, 0, 1203, { city: 2, building: "BUILDING_MUSEUM_ART", slot: 1 })).toEqual({ ok: true });
	});
});
