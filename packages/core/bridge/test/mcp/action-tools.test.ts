// Tests for mcp/action.ts and the action tools: each tool sends its call for
// the server's player, through an in-process client and the fake game. A tool
// gets the ok only when its exact call is answered.

import type { Client } from "@modelcontextprotocol/client";
import { beforeEach, describe, expect, test } from "vitest";
import { TOOK_REQUEST } from "../../src/mcp/action.js";
import { NOT_CONNECTED } from "../../src/mcp/results.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";
import { answerStash, callTool, connectTools } from "./tools.js";

const OK = { ok: true };
const DONE = { text: TOOK_REQUEST, isError: false };

let game: FakeGame;
let mcp: Client;

beforeEach(async () => {
	let client: TunerClient;

	({ game, client } = await startGame());
	mcp = await connectTools(client);
});

describe("registerAction", () => {
	test("returns that the game took the request", async () => {
		answerStash(game, { "SentientSystems_MoveUnit(3, 7, 10, 12)": OK });

		expect(await callTool(mcp, "move_unit", { unitID: 7, x: 10, y: 12 })).toEqual(DONE);
	});

	test("returns a failed action's reason as an error result", async () => {
		answerStash(game, { "SentientSystems_MoveUnit(3, 7, 10, 12)": { ok: false, reason: "The unit has no moves left." } });

		expect(await callTool(mcp, "move_unit", { unitID: 7, x: 10, y: 12 })).toEqual({ text: "The unit has no moves left.", isError: true });
	});

	test("answers at once when the bridge isn't connected to the game", async () => {
		const offline = await connectTools({ isConnected: false } as TunerClient);

		expect(await callTool(offline, "end_turn")).toEqual({ text: NOT_CONNECTED, isError: true });
	});
});

describe("unit_action", () => {
	test("passes an order with no fields, a field, or a tile", async () => {
		answerStash(game, {
			"SentientSystems_UnitAction(3, 7, \"fortify\", nil, nil, nil)": OK,
			"SentientSystems_UnitAction(3, 7, \"promote\", nil, nil, \"PROMOTION_BATTLECRY\")": OK,
			"SentientSystems_UnitAction(3, 7, \"wmd_strike\", 4, 5, \"WMD_NUCLEAR_DEVICE\")": OK,
		});

		expect(await callTool(mcp, "unit_action", { unitID: 7, action: "fortify" })).toEqual(DONE);
		expect(await callTool(mcp, "unit_action", { unitID: 7, action: "promote", promotion: "PROMOTION_BATTLECRY" })).toEqual(DONE);
		expect(await callTool(mcp, "unit_action", { unitID: 7, action: "wmd_strike", x: 4, y: 5, device: "WMD_NUCLEAR_DEVICE" })).toEqual(DONE);
	});

	test("refuses x without y, and sends nothing", async () => {
		expect(await callTool(mcp, "unit_action", { unitID: 7, action: "attack", x: 4 })).toEqual({ text: "Give both x and y, or neither.", isError: true });
		expect(game.commands).toEqual([]);
	});

	test("refuses an order the action API doesn't have", async () => {
		expect(await callTool(mcp, "unit_action", { unitID: 7, action: "dance" })).toMatchObject({ isError: true });
	});
});

describe("end_turn", () => {
	test("sends force only when it is given", async () => {
		answerStash(game, { "SentientSystems_EndTurn(3, false)": OK, "SentientSystems_EndTurn(3, true)": OK });

		expect(await callTool(mcp, "end_turn")).toEqual(DONE);
		expect(await callTool(mcp, "end_turn", { force: true })).toEqual(DONE);
	});
});
