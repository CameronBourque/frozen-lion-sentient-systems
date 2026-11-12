// Tests for spies.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { chooseEscapeRoute, spyMission, spyTravel } from "../../src/actions/spies.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("spy actions", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
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

	test("chooseEscapeRoute passes the route as text", async () => {
		answer("SentientSystems_ChooseEscapeRoute(0, \"DISTRICT_HARBOR\")", "{\"ok\":true}");

		expect(await chooseEscapeRoute(client, 0, "DISTRICT_HARBOR")).toEqual({ ok: true });
	});
});
