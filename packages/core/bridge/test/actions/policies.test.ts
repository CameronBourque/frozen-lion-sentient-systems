// Tests for policies.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { setGovernment, setPolicies, unlockPolicies } from "../../src/actions/policies.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("setPolicies", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("sends each slot by its number, with false for an empty slot", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetPolicies(0, {[0] = \"POLICY_DISCIPLINE\", [1] = false}))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await setPolicies(client, 0, ["POLICY_DISCIPLINE", null])).toEqual({ ok: true });
	});

	test("returns the core mod's reason", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetPolicies(0, {}))";
		const reason = "Give a policy, or none, for each of your 2 slots, 0 to 1, as the government choice lists them.";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] } })[lua] ?? {};

		expect(await setPolicies(client, 0, [])).toEqual({ ok: false, reason });
	});
});

describe("unlockPolicies", () => {
	test("sends the player's unlock", async () => {
		const { game, client } = await startGame();
		const stash = "SentientSystems_Stash(SentientSystems_UnlockPolicies(0))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await unlockPolicies(client, 0)).toEqual({ ok: true });
	});
});

describe("setGovernment", () => {
	test("sends the government's type", async () => {
		const { game, client } = await startGame();
		const stash = "SentientSystems_Stash(SentientSystems_SetGovernment(0, \"GOVERNMENT_AUTOCRACY\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await setGovernment(client, 0, "GOVERNMENT_AUTOCRACY")).toEqual({ ok: true });
	});
});
