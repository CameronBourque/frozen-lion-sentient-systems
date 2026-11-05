// Tests for units.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { moveUnit } from "../../src/actions/units.js";
import { CORE_STATE } from "../../src/connect.js";
import { TunerClient } from "../../src/tuner/client.js";
import { FakeGame } from "../tuner/fake-game.js";

describe("moveUnit", () => {
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

	test("asks the core mod to move the player's unit to the tile", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_MoveUnit(0, 196608, 11, 10))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":false,\"reason\":\"The unit has no moves left.\"}"] } })[lua] ?? {};

		expect(await moveUnit(client, 0, 196608, 11, 10)).toEqual({ ok: false, reason: "The unit has no moves left." });
		expect(game.commands[0]?.lua).toBe(stash);
	});
});
