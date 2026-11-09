// Tests for cities.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { cityAttack, purchase, purchaseTile, queueProduction, setProduction } from "../../src/actions/cities.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("cityAttack", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod for the city's shot at the tile", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_CityAttack(0, 262147, 38, 38))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":false,\"reason\":\"You can't see that tile.\"}"] } })[lua] ?? {};

		expect(await cityAttack(client, 0, 262147, { x: 38, y: 38 })).toEqual({ ok: false, reason: "You can't see that tile." });
	});
});

describe("setProduction and queueProduction", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to produce the item in the city", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetProduction(0, 65536, \"UNIT_BUILDER\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await setProduction(client, 0, 65536, "UNIT_BUILDER")).toEqual({ ok: true });
	});

	test("passes the tile of a district", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetProduction(0, 65536, \"DISTRICT_CAMPUS\", 21, 20))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await setProduction(client, 0, 65536, "DISTRICT_CAMPUS", { x: 21, y: 20 })).toEqual({ ok: true });
	});

	test("queues the item with append, and no tile", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetProduction(0, 65536, \"UNIT_BUILDER\", nil, nil, true))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await queueProduction(client, 0, 65536, "UNIT_BUILDER")).toEqual({ ok: true });
	});

	test("queues a district with its tile, then append", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_SetProduction(0, 65536, \"DISTRICT_CAMPUS\", 21, 20, true))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await queueProduction(client, 0, 65536, "DISTRICT_CAMPUS", { x: 21, y: 20 })).toEqual({ ok: true });
	});
});

describe("purchase", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to buy the item in the city with the yield", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_Purchase(0, 65536, \"UNIT_BUILDER\", \"gold\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await purchase(client, 0, 65536, "UNIT_BUILDER", "gold")).toEqual({ ok: true });
	});
});

describe("purchaseTile", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod to buy the tile for the city", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_PurchaseTile(0, 65536, 19, 14))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await purchaseTile(client, 0, 65536, { x: 19, y: 14 })).toEqual({ ok: true });
	});
});
