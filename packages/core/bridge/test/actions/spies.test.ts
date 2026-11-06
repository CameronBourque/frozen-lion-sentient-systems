// Tests for spies.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { spyMission, spyTravel } from "../../src/actions/spies.js";
import { CORE_STATE } from "../../src/connect.js";
import { TunerClient } from "../../src/tuner/client.js";
import { FakeGame } from "../tuner/fake-game.js";

describe("spy actions", () => {
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

	// Answers the call with the result.
	function answer(call: string, result: string): void {
		game.onCommand = (_stateIndex, lua) => ({ [`SentientSystems_Stash(${call})`]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [result] } })[lua] ?? {};
	}

	test("spyMission names the mission and passes no district as nil", async () => {
		answer("SentientSystems_SpyMission(0, 16580778, \"UNITOPERATION_SPY_GAIN_SOURCES\", nil)", "{\"ok\":true}");

		expect(await spyMission(client, 0, 16580778, "UNITOPERATION_SPY_GAIN_SOURCES")).toEqual({ ok: true });
	});

	test("spyMission passes the district of a counterspy mission as text", async () => {
		answer("SentientSystems_SpyMission(0, 16646315, \"UNITOPERATION_SPY_COUNTERSPY\", \"DISTRICT_COMMERCIAL_HUB\")", "{\"ok\":true}");

		expect(await spyMission(client, 0, 16646315, "UNITOPERATION_SPY_COUNTERSPY", "DISTRICT_COMMERCIAL_HUB")).toEqual({ ok: true });
	});

	test("spyTravel names the city by its owner and its ID", async () => {
		answer("SentientSystems_SpyTravel(0, 16711852, 0, 65536)", "{\"ok\":false,\"reason\":\"The spy is already in Aduatuca.\"}");

		expect(await spyTravel(client, 0, 16711852, 0, 65536)).toEqual({ ok: false, reason: "The spy is already in Aduatuca." });
	});
});
