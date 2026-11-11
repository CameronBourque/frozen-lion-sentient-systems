// Tests for envoys.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { sendEnvoys } from "../../src/actions/envoys.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("sendEnvoys", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to send the envoys, one when the count is left out", async () => {
		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_SendEnvoys(0, 27, 1))": { output: ["1"] },
			"SentientSystems_Stash(SentientSystems_SendEnvoys(0, 27, 2))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[lua] ?? {};

		expect(await sendEnvoys(client, 0, 27)).toEqual({ ok: true });
		expect(await sendEnvoys(client, 0, 27, 2)).toEqual({ ok: true });
	});
});
