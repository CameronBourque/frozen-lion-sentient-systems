// Tests for research.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { queueCivic, queueResearch, setCivic, setResearch } from "../../src/actions/research.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("setResearch, setCivic, queueResearch, and queueCivic", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to research the tech", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetResearch(0, \"TECH_MINING\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await setResearch(client, 0, "TECH_MINING")).toEqual({ ok: true });
	});

	test("asks the core mod to research the civic, and returns its reason", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetCivic(0, \"CIVIC_THEOLOGY\"))";
		const reason = "You have CIVIC_THEOLOGY already.";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] } })[lua] ?? {};

		expect(await setCivic(client, 0, "CIVIC_THEOLOGY")).toEqual({ ok: false, reason });
	});

	test("passes append to queue the tech or civic", async () => {
		const ok = { output: ["{\"ok\":true}"] };

		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_SetResearch(0, \"TECH_IRON_WORKING\", true))": { output: ["1"] },
			"SentientSystems_Stash(SentientSystems_SetCivic(0, \"CIVIC_THEOLOGY\", true))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": ok,
		})[lua] ?? {};

		expect(await queueResearch(client, 0, "TECH_IRON_WORKING")).toEqual({ ok: true });
		expect(await queueCivic(client, 0, "CIVIC_THEOLOGY")).toEqual({ ok: true });
	});
});
