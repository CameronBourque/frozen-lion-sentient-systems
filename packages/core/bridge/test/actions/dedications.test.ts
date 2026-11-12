// Tests for dedications.ts, against the fake game.

import { describe, expect, test } from "vitest";
import { chooseDedications } from "../../src/actions/dedications.js";
import { startGame } from "../tuner/fake-game.js";

describe("chooseDedications", () => {
	test("passes the dedications as a Lua list", async () => {
		const { game, client } = await startGame();
		const lua = "SentientSystems_ChooseDedications(0, {\"COMMEMORATION_SCIENTIFIC\", \"COMMEMORATION_CULTURAL\"})";

		game.onCommand = (_stateIndex, command) => ({
			[`SentientSystems_Stash(${lua})`]: { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[command] ?? {};

		expect(await chooseDedications(client, 0, ["COMMEMORATION_SCIENTIFIC", "COMMEMORATION_CULTURAL"])).toEqual({ ok: true });
	});
});
