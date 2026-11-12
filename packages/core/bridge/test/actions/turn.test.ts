// Tests for turn.ts, against the fake game.

import { describe, expect, test } from "vitest";
import { endTurn } from "../../src/actions/turn.js";
import { startGame } from "../tuner/fake-game.js";

describe("endTurn", () => {
	test.each([
		{ force: undefined, lua: "SentientSystems_EndTurn(0, false)" },
		{ force: true, lua: "SentientSystems_EndTurn(0, true)" },
	])("sends force as $force", async ({ force, lua }) => {
		const { game, client } = await startGame();

		game.onCommand = (_stateIndex, command) => ({
			[`SentientSystems_Stash(${lua})`]: { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[command] ?? {};

		expect(await endTurn(client, 0, force)).toEqual({ ok: true });
	});
});
