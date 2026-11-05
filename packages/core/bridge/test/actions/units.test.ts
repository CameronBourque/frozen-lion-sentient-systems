// Tests for units.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { moveUnit, unitAction } from "../../src/actions/units.js";
import { CORE_STATE } from "../../src/connect.js";
import { TunerClient } from "../../src/tuner/client.js";
import { FakeGame } from "../tuner/fake-game.js";

const FAILED = "{\"ok\":false,\"reason\":\"The unit has no moves left.\"}";

describe("unit actions", () => {
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

	// Answers the stash of the call with one piece that holds json.
	function answer(call: string, json: string): void {
		const stash = `SentientSystems_Stash(${call})`;

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [json] } })[lua] ?? {};
	}

	test("moveUnit asks the core mod to move the player's unit to the tile", async () => {
		answer("SentientSystems_MoveUnit(0, 196608, 11, 10)", FAILED);

		expect(await moveUnit(client, 0, 196608, 11, 10)).toEqual({ ok: false, reason: "The unit has no moves left." });
		expect(game.commands[0]?.lua).toBe("SentientSystems_Stash(SentientSystems_MoveUnit(0, 196608, 11, 10))");
	});

	test("unitAction asks the core mod for a stance", async () => {
		answer("SentientSystems_UnitAction(0, 6160397, \"fortify\", nil, nil, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 6160397, { action: "fortify" })).toEqual({ ok: true });
	});

	test("unitAction passes the tile of an attack", async () => {
		answer("SentientSystems_UnitAction(0, 4456460, \"attack\", 38, 38, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 4456460, { action: "attack", x: 38, y: 38 })).toEqual({ ok: true });
	});

	test("unitAction passes an improvement as text", async () => {
		answer("SentientSystems_UnitAction(0, 9437197, \"improve\", nil, nil, \"IMPROVEMENT_FARM\")", "{\"ok\":true}");

		expect(await unitAction(client, 0, 9437197, { action: "improve", improvement: "IMPROVEMENT_FARM" })).toEqual({ ok: true });
	});

	test("unitAction passes a promotion as text, with its quotes escaped", async () => {
		answer("SentientSystems_UnitAction(0, 5636113, \"promote\", nil, nil, \"PROMOTION_\\\"HULL\")", FAILED);

		expect(await unitAction(client, 0, 5636113, { action: "promote", promotion: "PROMOTION_\"HULL" })).toEqual({ ok: false, reason: "The unit has no moves left." });
	});
});
