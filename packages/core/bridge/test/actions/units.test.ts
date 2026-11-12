// Tests for units.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { moveUnit, unitAction } from "../../src/actions/units.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

const FAILED = "{\"ok\":false,\"reason\":\"The unit has no moves left.\"}";

describe("unit actions", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	function answer(call: string, json: string): void {
		const stash = `SentientSystems_Stash(${call})`;

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [json] } })[lua] ?? {};
	}

	test("moveUnit asks the core mod to move the player's unit to the tile", async () => {
		answer("SentientSystems_MoveUnit(0, 196608, 11, 10)", FAILED);

		expect(await moveUnit(client, 0, 196608, { x: 11, y: 10 })).toEqual({ ok: false, reason: "The unit has no moves left." });
		expect(game.commands[0]?.lua).toBe("SentientSystems_Stash(SentientSystems_MoveUnit(0, 196608, 11, 10))");
	});

	test("unitAction asks the core mod for a stance", async () => {
		answer("SentientSystems_UnitAction(0, 6160397, \"fortify\", nil, nil, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 6160397, { action: "fortify" })).toEqual({ ok: true });
	});

	test("unitAction asks for a great person's activation with no argument", async () => {
		answer("SentientSystems_UnitAction(0, 5898263, \"activate\", nil, nil, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 5898263, { action: "activate" })).toEqual({ ok: true });
	});

	test("unitAction asks for a religious order with no argument", async () => {
		answer("SentientSystems_UnitAction(0, 3801115, \"found_religion\", nil, nil, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 3801115, { action: "found_religion" })).toEqual({ ok: true });
	});

	test("unitAction passes the tile of an attack", async () => {
		answer("SentientSystems_UnitAction(0, 4456460, \"attack\", 38, 38, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 4456460, { action: "attack", x: 38, y: 38 })).toEqual({ ok: true });
	});

	test("unitAction asks for a builder job on the unit's tile with no argument", async () => {
		answer("SentientSystems_UnitAction(0, 7405612, \"clear_fallout\", nil, nil, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 7405612, { action: "clear_fallout" })).toEqual({ ok: true });
	});

	test("unitAction passes the tile and the device of a strike", async () => {
		answer("SentientSystems_UnitAction(0, 9371649, \"wmd_strike\", 50, 30, \"WMD_THERMONUCLEAR_DEVICE\")", "{\"ok\":true}");

		expect(await unitAction(client, 0, 9371649, { action: "wmd_strike", x: 50, y: 30, device: "WMD_THERMONUCLEAR_DEVICE" })).toEqual({ ok: true });
	});

	test("unitAction passes an improvement as text", async () => {
		answer("SentientSystems_UnitAction(0, 9437197, \"improve\", nil, nil, \"IMPROVEMENT_FARM\")", "{\"ok\":true}");

		expect(await unitAction(client, 0, 9437197, { action: "improve", improvement: "IMPROVEMENT_FARM" })).toEqual({ ok: true });
	});

	test("unitAction passes the route of a road as text", async () => {
		answer("SentientSystems_UnitAction(0, 9437197, \"build_road\", nil, nil, \"ROUTE_RAILROAD\")", "{\"ok\":true}");

		expect(await unitAction(client, 0, 9437197, { action: "build_road", route: "ROUTE_RAILROAD" })).toEqual({ ok: true });
	});

	test("unitAction passes a road with no route, a job, and an upgrade, with no type", async () => {
		answer("SentientSystems_UnitAction(0, 9437197, \"build_road\", nil, nil, nil)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9437197, { action: "build_road" })).toEqual({ ok: true });

		answer("SentientSystems_UnitAction(0, 9437197, \"harvest\", nil, nil, nil)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9437197, { action: "harvest" })).toEqual({ ok: true });

		answer("SentientSystems_UnitAction(0, 9437197, \"add_production\", nil, nil, nil)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9437197, { action: "add_production" })).toEqual({ ok: true });

		answer("SentientSystems_UnitAction(0, 9437197, \"upgrade\", nil, nil, nil)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9437197, { action: "upgrade" })).toEqual({ ok: true });
	});

	test("unitAction passes the tile of an air move and a priority target", async () => {
		answer("SentientSystems_UnitAction(0, 9306120, \"rebase\", 43, 38, nil)", "{\"ok\":true}");

		expect(await unitAction(client, 0, 9306120, { action: "rebase", x: 43, y: 38 })).toEqual({ ok: true });

		answer("SentientSystems_UnitAction(0, 9306120, \"priority_target\", 44, 39, nil)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9306120, { action: "priority_target", x: 44, y: 39 })).toEqual({ ok: true });
	});

	test("unitAction passes the unit to join as a number", async () => {
		answer("SentientSystems_UnitAction(0, 9437197, \"form_corps\", nil, nil, 9502792)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9437197, { action: "form_corps", with: 9502792 })).toEqual({ ok: true });

		answer("SentientSystems_UnitAction(0, 9437197, \"exit_formation\", nil, nil, nil)", "{\"ok\":true}");
		expect(await unitAction(client, 0, 9437197, { action: "exit_formation" })).toEqual({ ok: true });
	});

	test("unitAction passes a promotion as text, with its quotes escaped", async () => {
		answer("SentientSystems_UnitAction(0, 5636113, \"promote\", nil, nil, \"PROMOTION_\\\"HULL\")", FAILED);

		expect(await unitAction(client, 0, 5636113, { action: "promote", promotion: "PROMOTION_\"HULL" })).toEqual({ ok: false, reason: "The unit has no moves left." });
	});
});
