// Tests for research.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { setCivic, setResearch } from "../../src/actions/research.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("setResearch and setCivic", () => {
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
		const reason = "CIVIC_THEOLOGY isn't one of the civics you can research now.";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] } })[lua] ?? {};

		expect(await setCivic(client, 0, "CIVIC_THEOLOGY")).toEqual({ ok: false, reason });
	});
});
