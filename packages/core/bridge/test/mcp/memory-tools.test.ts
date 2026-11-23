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

describe("record_decision and record_result", () => {
	const WAR = { decision: "Declare war on Rome.", reason: "Their capital is weak." };

	test("record each decision under the turn with the next id, then its result", async () => {
		const mcp = await connect();

		answerTurn(["5"]);
		expect(await call(mcp, "record_decision", WAR)).toEqual({ text: "Recorded decision 1.", isError: false });
		expect(await call(mcp, "record_decision", { decision: "Build a wall.", reason: "Rome is close." })).toEqual({ text: "Recorded decision 2.", isError: false });
		expect(await call(mcp, "record_result", { id: 1, result: "Took two cities." })).toEqual({ text: "Recorded the result of decision 1.", isError: false });

		expect(readMemory(folder(3), NOW).memory.decisions).toEqual([
			{ id: 1, turn: 5, ...WAR, result: "Took two cities." },
			{ id: 2, turn: 5, decision: "Build a wall.", reason: "Rome is close." },
		]);
	});

	test("record_result fails for an id no decision has", async () => {
		expect(await call(await connect(), "record_result", { id: 4, result: "Took two cities." })).toEqual({ text: "No decision has the id 4.", isError: true });
	});

	test("record_decision writes nothing when the game gives no turn", async () => {
		answerTurn([]);

		expect(await call(await connect(), "record_decision", WAR)).toMatchObject({ isError: true });
		expect(fs.existsSync(folder(3))).toBe(false);
	});

	test("record_decision fails when it can't write the folder", async () => {
		const blocked = path.join(root, "a-file");

		fs.writeFileSync(blocked, "");
		answerTurn(["5"]);

		expect(await call(await connect(() => blocked), "record_decision", WAR)).toMatchObject({ text: expect.stringContaining("Couldn't save your decision") as unknown, isError: true });
	});

	test("record_result fails when it can't read or write the file", async () => {
		fs.mkdirSync(path.join(folder(3), "decisions.jsonl"), { recursive: true });

		expect(await call(await connect(), "record_result", { id: 1, result: "Took two cities." })).toMatchObject({ text: expect.stringContaining("Couldn't save your result") as unknown, isError: true });
	});

	test("a decisions file it can't read moves aside, and the ids start again", async () => {
		fs.mkdirSync(folder(3), { recursive: true });
		fs.writeFileSync(path.join(folder(3), "decisions.jsonl"), "not JSON\n");
		answerTurn(["5"]);

		expect(await call(await connect(), "record_decision", WAR)).toEqual({ text: "Recorded decision 1.", isError: false });
		expect(fs.readdirSync(folder(3)).some((name) => name.startsWith("decisions.jsonl.unreadable-"))).toBe(true);
	});
});

// The check that closed the memory step of phase 2.
test("two fake turns through the tools leave the second plan, both entries, and one decision with its result", async () => {
	const mcp = await connect();

	answerTurn(["4"]);
	await call(mcp, "update_plan", { plan: "Take the coast." });
	await call(mcp, "add_journal_entry", { entry: "Met Rome." });
	await call(mcp, "record_decision", { decision: "Settle the coast.", reason: "Fish and a harbor." });

	answerTurn(["5"]);
	await call(mcp, "update_plan", { plan: "Build a navy." });
	await call(mcp, "add_journal_entry", { entry: "Rome denounced us." });
	await call(mcp, "record_result", { id: 1, result: "The city grew fast." });

	expect(readMemory(folder(3), NOW).memory).toEqual({
		plan: "Build a navy.",
		journal: [{ turn: 4, text: "Met Rome." }, { turn: 5, text: "Rome denounced us." }],
		decisions: [{ id: 1, turn: 4, decision: "Settle the coast.", reason: "Fish and a harbor.", result: "The city grew fast." }],
	});
});
