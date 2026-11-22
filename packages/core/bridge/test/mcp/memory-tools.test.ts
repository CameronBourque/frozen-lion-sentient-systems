// Tests for mcp/memory-tools.ts: each tool writes the server's player's memory
// folder, through an in-process client and the fake game. The store has its own
// tests.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { Client } from "@modelcontextprotocol/client";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { readMemory } from "../../src/memory/store.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";
import { PLAYER_3, QUIET, callTool as call, connectTools } from "./tools.js";

const NOW = new Date("2026-11-21T10:20:30.456Z");

let root: string;
let game: FakeGame;
let client: TunerClient;

beforeEach(async () => {
	root = fs.mkdtempSync(path.join(os.tmpdir(), "memory-tools-"));
	({ game, client } = await startGame());
});

afterEach(() => {
	fs.rmSync(root, { recursive: true, force: true });
});

function folder(playerID: number): string {
	return path.join(root, `player-${playerID}`);
}

function connect(memory = folder): Promise<Client> {
	return connectTools(client, PLAYER_3, QUIET, memory);
}

function answerTurn(output: string[]): void {
	game.onCommand = (_stateIndex, lua) => (lua === "print(Game.GetCurrentGameTurn())" ? { output } : {});
}

describe("update_plan", () => {
	test("replaces the plan in the server's player's folder", async () => {
		const mcp = await connect();

		expect(await call(mcp, "update_plan", { plan: "Take the coast." })).toEqual({ text: "Saved your plan.", isError: false });
		await call(mcp, "update_plan", { plan: "Build a navy." });

		expect(readMemory(folder(3), NOW).memory.plan).toBe("Build a navy.");
	});

	test("refuses a plan over 2000 characters", async () => {
		expect(await call(await connect(), "update_plan", { plan: "a".repeat(2001) })).toMatchObject({ isError: true });
		expect(fs.existsSync(folder(3))).toBe(false);
	});

	test("fails when it can't write the folder", async () => {
		const blocked = path.join(root, "a-file");

		fs.writeFileSync(blocked, "");

		expect(await call(await connect(() => blocked), "update_plan", { plan: "Take the coast." })).toMatchObject({ text: expect.stringContaining("Couldn't save your plan") as unknown, isError: true });
	});
});

describe("add_journal_entry", () => {
	test("appends each entry under the game's current turn", async () => {
		const mcp = await connect();

		answerTurn(["4"]);
		expect(await call(mcp, "add_journal_entry", { entry: "Met Rome." })).toEqual({ text: "Added the entry to your journal for turn 4.", isError: false });
		answerTurn(["5"]);
		await call(mcp, "add_journal_entry", { entry: "Settled a second city." });

		expect(readMemory(folder(3), NOW).memory.journal).toEqual([{ turn: 4, text: "Met Rome." }, { turn: 5, text: "Settled a second city." }]);
	});

	test("writes nothing when the game gives no turn", async () => {
		answerTurn(["nil"]);

		expect(await call(await connect(), "add_journal_entry", { entry: "Met Rome." })).toEqual({ text: "Game.GetCurrentGameTurn() printed [\"nil\"], not a turn", isError: true });
		expect(fs.existsSync(folder(3))).toBe(false);
	});

	test("fails when it can't write the folder", async () => {
		const blocked = path.join(root, "a-file");

		fs.writeFileSync(blocked, "");
		answerTurn(["4"]);

		expect(await call(await connect(() => blocked), "add_journal_entry", { entry: "Met Rome." })).toMatchObject({ text: expect.stringContaining("Couldn't save your journal") as unknown, isError: true });
	});
});
