// Tests for actions.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { sendAction } from "../../src/actions/actions.js";
import { CORE_STATE } from "../../src/connect.js";
import { TunerClient } from "../../src/tuner/client.js";
import type { CommandResult } from "../tuner/fake-game.js";
import { FakeGame } from "../tuner/fake-game.js";

const CALL = "SentientSystems_MoveUnit(0, 65536, 12, 8)";
const STASH = `SentientSystems_Stash(${CALL})`;

describe("sendAction", () => {
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

	function stash(json: string): void {
		const results: Record<string, CommandResult> = { [STASH]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [json] } };

		game.onCommand = (_stateIndex, lua) => results[lua] ?? {};
	}

	test("runs the call in the core mod's state and returns a success", async () => {
		stash("{\"ok\":true}");

		expect(await sendAction(client, CALL)).toEqual({ ok: true });
		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: STASH },
			{ stateIndex: 130, lua: "SentientSystems_PrintPiece(1)" },
		]);
	});

	test("returns the reason of a failure", async () => {
		stash("{\"ok\":false,\"reason\":\"That tile is out of reach.\"}");

		expect(await sendAction(client, CALL)).toEqual({ ok: false, reason: "That tile is out of reach." });
	});

	test("returns a failure without a reason as a failed result", async () => {
		stash("{\"ok\":false}");

		const result = await sendAction(client, CALL);

		expect(result.ok).toBe(false);
		expect(result.ok === false && result.reason).toContain("doesn't match the schema");
	});

	test("returns the game's error as a failed result", async () => {
		game.onCommand = () => ({ luaError: "attempt to call a nil value\nstack traceback:" });

		expect(await sendAction(client, CALL)).toEqual({ ok: false, reason: "The core mod failed to build the action result: attempt to call a nil value" });
	});
});
