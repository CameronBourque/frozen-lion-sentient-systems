// Tests for cities.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { cityAttack } from "../../src/actions/cities.js";
import { CORE_STATE } from "../../src/connect.js";
import { TunerClient } from "../../src/tuner/client.js";
import { FakeGame } from "../tuner/fake-game.js";

describe("cityAttack", () => {
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

	test("asks the core mod for the city's shot at the tile", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_CityAttack(0, 262147, 38, 38))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":false,\"reason\":\"You can't see that tile.\"}"] } })[lua] ?? {};

		expect(await cityAttack(client, 0, 262147, 38, 38)).toEqual({ ok: false, reason: "You can't see that tile." });
	});
});
