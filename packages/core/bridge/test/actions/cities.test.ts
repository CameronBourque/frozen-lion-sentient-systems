// Tests for cities.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { cityAttack, purchase, setProduction } from "../../src/actions/cities.js";
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

describe("setProduction", () => {
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
});

describe("purchase", () => {
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

	test("asks the core mod to buy the item in the city with the yield", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_Purchase(0, 65536, \"UNIT_BUILDER\", \"gold\"))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await purchase(client, 0, 65536, "UNIT_BUILDER", "gold")).toEqual({ ok: true });
	});
});

