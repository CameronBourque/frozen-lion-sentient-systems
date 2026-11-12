// Tests for wmds.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { siloStrike } from "../../src/actions/wmds.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("siloStrike", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to launch the device from the silo at the tile", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SiloStrike(0, 44, 30, 50, 30, \"WMD_NUCLEAR_DEVICE\"))";
		const json = "{\"ok\":false,\"reason\":\"Striking there would start a war with player 4.\"}";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [json] } })[lua] ?? {};

		expect(await siloStrike(client, 0, { x: 44, y: 30 }, { x: 50, y: 30 }, "WMD_NUCLEAR_DEVICE")).toEqual({
			ok: false,
			reason: "Striking there would start a war with player 4.",
		});
	});
});
