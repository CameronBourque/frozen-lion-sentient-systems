// Tests for agents/turn-signal.ts: turn signals start a mock model's turns
// through the fake game.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { MockLanguageModelV4 } from "ai/test";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { type SignalContext, turnSignal } from "../../src/agents/turn-signal.js";
import { NO_MODEL } from "../../src/config.js";
import type { CoreEvent } from "../../src/events.js";
import { Logger } from "../../src/log.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { answerStash } from "../mcp/tools.js";
import { type StreamResult, reply, scripted } from "../model/mock-model.js";
import { MINIMAL_STATE } from "../state/minimal-state.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

const TURN_3: CoreEvent = { type: "turn", playerId: 3, again: false };

let game: FakeGame;
let client: TunerClient;
let root: string;
let logger: Logger;

beforeEach(async () => {
	({ game, client } = await startGame());
	root = fs.mkdtempSync(path.join(os.tmpdir(), "signal-"));
	logger = new Logger("error");
	answerStash(game, {
		"SentientSystems_GetState(3)": MINIMAL_STATE,
		"SentientSystems_EndTurn(3, false)": { ok: true },
	});
});

afterEach(() => {
	fs.rmSync(root, { recursive: true, force: true, maxRetries: 3 });
});

function endTurn(): StreamResult {
	return reply([{ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: JSON.stringify({ reason: "Done." }) }]);
}

// Agents with no knowledge files, so each prompt build warns.
function context(model: MockLanguageModelV4, memory = (playerID: number) => path.join(root, `player-${playerID}`)): SignalContext {
	return {
		client,
		logger,
		target: { model, provider: "anthropic", mode: "api-key", effort: "" },
		model: NO_MODEL,
		journalEntries: 5,
		now: () => new Date("2026-11-26T12:00:00Z"),
		knowledge: new Map(),
		memory,
	};
}

function sent(): string[] {
	return game.commands.map(({ lua }) => lua);
}

test("a turn signal plays that player's turn, with tools that act for it", async () => {
	const info = vi.spyOn(logger, "info");

	await turnSignal(context(scripted([endTurn()])))(TURN_3);

	expect(sent().some((lua) => lua.includes("SentientSystems_EndTurn(3, false)"))).toBe(true);
	expect(info).toHaveBeenCalledWith("turn_ended", "Player 3 ended its turn", { player: 3 });
});

test("other events start no turn", async () => {
	const model = scripted([]);

	await turnSignal(context(model))({ type: "game_ready", turn: 1 });

	expect(model.doStreamCalls).toEqual([]);
	expect(sent()).toEqual([]);
});

test("a signal while the player's turn is still running is skipped", async () => {
	const info = vi.spyOn(logger, "info");
	const model = scripted([endTurn()]);
	const onTurn = turnSignal(context(model));

	await Promise.all([onTurn(TURN_3), onTurn({ ...TURN_3, again: true })]);

	expect(model.doStreamCalls).toHaveLength(1);
	expect(info).toHaveBeenCalledWith("turn_skipped", "Player 3's turn is already being played", { player: 3 });
});

test("each agent is built once, and later turns reuse it", async () => {
	const warn = vi.spyOn(logger, "warn");
	const model = scripted([endTurn(), endTurn()]);
	const onTurn = turnSignal(context(model));

	await onTurn(TURN_3);
	await onTurn(TURN_3);

	expect(model.doStreamCalls).toHaveLength(2);
	// The personality and the sweat level each warn, once.
	expect(warn.mock.calls.filter(([event]) => event === "prompt_warning")).toHaveLength(2);
});

test("a turn that stops logs no end", async () => {
	const info = vi.spyOn(logger, "info");
	const thinking = (): StreamResult => reply([{ type: "text", text: "Hmm." }]);

	await turnSignal(context(scripted([thinking(), thinking()])))(TURN_3);

	expect(info).not.toHaveBeenCalledWith("turn_ended", expect.anything(), expect.anything());
});

test("a turn that throws warns, and the next signal tries again", async () => {
	const warn = vi.spyOn(logger, "warn");
	let calls = 0;

	const memory = (playerID: number): string => {
		calls += 1;

		if (calls === 1) {
			throw new Error("No memory folder");
		}

		return path.join(root, `player-${playerID}`);
	};

	const model = scripted([endTurn()]);
	const onTurn = turnSignal(context(model, memory));

	await onTurn(TURN_3);

	expect(warn).toHaveBeenCalledWith("turn_failed", "Player 3's turn failed: Error: No memory folder", { player: 3, reason: "Error: No memory folder" });

	await onTurn(TURN_3);

	expect(model.doStreamCalls).toHaveLength(1);
});
