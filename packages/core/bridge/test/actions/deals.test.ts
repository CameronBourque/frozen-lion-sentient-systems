// Tests for deals.ts, against the fake game.

import { describe, expect, test } from "vitest";
import { respondToDeal } from "../../src/actions/deals.js";
import { startGame } from "../tuner/fake-game.js";

describe("respondToDeal", () => {
	test("passes the players and the answer", async () => {
		const { game, client } = await startGame();
		const lua = "SentientSystems_RespondToDeal(0, 4, false)";

		game.onCommand = (_stateIndex, command) => ({
			[`SentientSystems_Stash(${lua})`]: { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[command] ?? {};

		expect(await respondToDeal(client, 0, 4, false)).toEqual({ ok: true });
	});
});
