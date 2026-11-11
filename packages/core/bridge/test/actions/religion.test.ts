// Tests for religion.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { addBelief, foundPantheon, foundReligion } from "../../src/actions/religion.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("foundPantheon", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to found the pantheon", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_FoundPantheon(0, \"BELIEF_RELIGIOUS_SETTLEMENTS\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await foundPantheon(client, 0, "BELIEF_RELIGIOUS_SETTLEMENTS")).toEqual({ ok: true });
	});

	test("returns the core mod's reason", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_FoundPantheon(0, \"BELIEF_DESERT_FOLKLORE\"))";
		const reason = "Another player has BELIEF_DESERT_FOLKLORE already. Use a type from the pantheon choice.";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] } })[lua] ?? {};

		expect(await foundPantheon(client, 0, "BELIEF_DESERT_FOLKLORE")).toEqual({ ok: false, reason });
	});
});

describe("foundReligion", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to found the religion with its beliefs, and a name when given", async () => {
		const ok = { output: ["{\"ok\":true}"] };

		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_FoundReligion(0, \"RELIGION_BUDDHISM\", {\"BELIEF_FEED_THE_WORLD\", \"BELIEF_GURDWARA\"}))": { output: ["1"] },
			"SentientSystems_Stash(SentientSystems_FoundReligion(0, \"RELIGION_CUSTOM_1\", {\"BELIEF_FEED_THE_WORLD\", \"BELIEF_GURDWARA\"}, \"Way of the Lion\"))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": ok,
		})[lua] ?? {};

		expect(await foundReligion(client, 0, "RELIGION_BUDDHISM", ["BELIEF_FEED_THE_WORLD", "BELIEF_GURDWARA"])).toEqual({ ok: true });
		expect(await foundReligion(client, 0, "RELIGION_CUSTOM_1", ["BELIEF_FEED_THE_WORLD", "BELIEF_GURDWARA"], "Way of the Lion")).toEqual({ ok: true });
	});
});

describe("addBelief", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to add the belief", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_AddBelief(0, \"BELIEF_TITHE\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await addBelief(client, 0, "BELIEF_TITHE")).toEqual({ ok: true });
	});
});
