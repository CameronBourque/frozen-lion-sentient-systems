// Tests for city-fate.ts, against the fake game.

import { describe, expect, test } from "vitest";
import { decideCity } from "../../src/actions/city-fate.js";
import { startGame } from "../tuner/fake-game.js";

describe("decideCity", () => {
	test("asks the core mod to decide the city's fate", async () => {
		const { game, client } = await startGame();

		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_DecideCity(0, 131073, \"RAZE\"))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[lua] ?? {};

		expect(await decideCity(client, 0, 131073, "RAZE")).toEqual({ ok: true });
	});
});
