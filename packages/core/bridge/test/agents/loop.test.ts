// Tests for agents/loop.ts: a mock model plays a turn through the bridge's
// MCP server and the fake game.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { APICallError } from "ai";
import type { MockLanguageModelV4 } from "ai/test";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { type Agent, type LoopContext, playTurn } from "../../src/agents/loop.js";
import { NO_MODEL } from "../../src/config.js";
import { Logger } from "../../src/log.js";
import { toolDefinitions } from "../../src/mcp/in-process.js";
import { addJournalEntry } from "../../src/memory/store.js";
import { type TunerClient, TunerTimeoutError } from "../../src/tuner/client.js";
import { answerStash, connectTools } from "../mcp/tools.js";
import { type Content, reply, scripted, waitingForAbort } from "../model/mock-model.js";
import { MINIMAL_STATE } from "../state/minimal-state.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

const SYSTEM = "You play Civilization VI.";
const REASON = "Nothing left to do.";

let game: FakeGame;
let client: TunerClient;
let root: string;
let folder: string;
let logger: Logger;

beforeEach(async () => {
	({ game, client } = await startGame());
	root = fs.mkdtempSync(path.join(os.tmpdir(), "loop-"));
	// startMemory moves the folder aside next to itself, inside root.
	folder = path.join(root, "player-3");
	logger = new Logger("error");
	answerStash(game, {
		"SentientSystems_GetState(3)": MINIMAL_STATE,
		"SentientSystems_EndTurn(3, false)": { ok: false, reason: "Choose a research." },
		"SentientSystems_EndTurn(3, true)": { ok: true },
	});
});

afterEach(() => {
	fs.rmSync(root, { recursive: true, force: true, maxRetries: 3 });
});

async function agent(first = false): Promise<Agent> {
	const tools = await connectTools(client, undefined, logger, () => folder);

	return { playerID: 3, system: SYSTEM, tools, definitions: await toolDefinitions(tools), memoryFolder: folder, first };
}

function context(model: MockLanguageModelV4): LoopContext {
	return { client, logger, target: { model, provider: "anthropic", mode: "api-key", effort: "" }, model: NO_MODEL, journalEntries: 5, now: () => new Date("2026-11-25T12:00:00Z") };
}

function endTurn(id: string, force: boolean): Content {
	return { type: "tool-call", toolCallId: id, toolName: "end_turn", input: JSON.stringify({ reason: REASON, force }) };
}

// Moves the game to turn 2, and keeps the other answers.
function nextTurn(): void {
	answerStash(game, {
		"SentientSystems_GetState(3)": { ...MINIMAL_STATE, turn: 2 },
		"SentientSystems_EndTurn(3, true)": { ok: true },
	});
}

function lua(): string[] {
	return game.commands.map(({ lua: text }) => text);
}

test("sends the system prompt and the turn message, and ends when end_turn goes through", async () => {
	const model = scripted([reply([endTurn("call-1", true)])]);

	expect(await playTurn(await agent(), context(model))).toEqual({ ended: true });

	const [system, turn] = model.doStreamCalls[0].prompt;

	expect(system).toEqual({ role: "system", content: SYSTEM });
	expect(turn).toMatchObject({ role: "user", content: [{ type: "text", text: expect.stringContaining("# Turn 1") as unknown }] });
	expect(lua().some((text) => text.includes("SentientSystems_EndTurn(3, true)"))).toBe(true);
});

test("a blocked end_turn goes back to the model with its reason, and the model tries again", async () => {
	const model = scripted([reply([endTurn("call-1", false)]), reply([endTurn("call-2", true)])]);

	expect(await playTurn(await agent(), context(model))).toEqual({ ended: true });

	const second = model.doStreamCalls[1].prompt;

	expect(second.at(-2)).toMatchObject({ role: "assistant", content: [{ type: "tool-call", toolCallId: "call-1" }] });
	expect(second.at(-1)).toMatchObject({ role: "tool", content: [{ type: "tool-result", toolCallId: "call-1", output: { type: "error-text", value: expect.stringContaining("Choose a research.") as unknown } }] });
});

test("a failed call logs why it failed, and a call that goes through logs no failure", async () => {
	const debug = vi.spyOn(logger, "debug");

	await playTurn(await agent(), context(scripted([reply([endTurn("call-1", false)]), reply([endTurn("call-2", true)])])));

	const [failed, done] = debug.mock.calls.filter(([event]) => event === "tool_call");

	expect(failed[1]).toMatch(/^end_turn: failed: .*Choose a research\./);
	expect(failed[2]).toMatchObject({ ok: false, failure: expect.stringContaining("Choose a research.") as unknown });
	expect(done[1]).toBe("end_turn: done");
	expect(done[2]).not.toHaveProperty("failure");
});

test("every call in a reply runs in order, and its result goes back", async () => {
	const plan: Content = { type: "tool-call", toolCallId: "call-1", toolName: "update_plan", input: JSON.stringify({ plan: "Build a settler." }) };
	const model = scripted([reply([plan, endTurn("call-2", false)]), reply([endTurn("call-3", true)])]);

	await playTurn(await agent(), context(model));

	expect(model.doStreamCalls[1].prompt.at(-1)).toMatchObject({
		role: "tool",
		content: [
			{ toolCallId: "call-1", output: { type: "text" } },
			{ toolCallId: "call-2", output: { type: "error-text" } },
		],
	});
	expect(fs.readFileSync(path.join(folder, "plan.md"), "utf8")).toContain("Build a settler.");
});

test("the calls after an end_turn that goes through don't run", async () => {
	const plan: Content = { type: "tool-call", toolCallId: "call-2", toolName: "update_plan", input: JSON.stringify({ plan: "Too late." }) };

	await playTurn(await agent(), context(scripted([reply([endTurn("call-1", true), plan])])));

	expect(fs.existsSync(path.join(folder, "plan.md"))).toBe(false);
});

test("a reply with no tool call gets a nudge, and the model acts", async () => {
	const model = scripted([reply([{ type: "text", text: "Let me think." }]), reply([endTurn("call-1", true)])]);

	expect(await playTurn(await agent(), context(model))).toEqual({ ended: true });
	expect(model.doStreamCalls[1].prompt.at(-1)).toEqual({ role: "user", content: [{ type: "text", text: expect.stringContaining("call end_turn") as unknown }] });
});

test("two replies in a row with no tool call stop the turn without an end turn", async () => {
	const warn = vi.spyOn(logger, "warn");
	const model = scripted([reply([{ type: "text", text: "Hmm." }]), reply([{ type: "text", text: "Still thinking." }])]);

	expect(await playTurn(await agent(), context(model))).toEqual({ ended: false, reason: "The model called no tool twice in a row. It wrote: Still thinking." });
	expect(warn).toHaveBeenCalledWith("turn_stopped", expect.stringContaining("Still thinking."), expect.objectContaining({ player: 3 }));
	expect(lua().some((text) => text.includes("EndTurn"))).toBe(false);
});

test("a nudge resets once the model calls a tool", async () => {
	const think: Content = { type: "text", text: "Hmm." };
	const model = scripted([reply([think]), reply([endTurn("call-1", false)]), reply([think]), reply([endTurn("call-2", true)])]);

	expect(await playTurn(await agent(), context(model))).toEqual({ ended: true });
});

test("a failed model call stops the turn with its reason", async () => {
	const model = scripted([]);

	model.doStream = () => Promise.reject(new APICallError({ message: "Bad key", url: "https://api.example.com", requestBodyValues: {}, statusCode: 401 }));

	expect(await playTurn(await agent(), context(model))).toMatchObject({ ended: false, reason: expect.stringContaining("Bad key") as unknown });
});

test("a state that can't be read stops the turn before the model is called", async () => {
	answerStash(game, { "SentientSystems_GetState(3)": {} });

	const model = scripted([]);

	expect(await playTurn(await agent(), context(model))).toMatchObject({ ended: false, reason: expect.stringContaining("The state couldn't be read") as unknown });
	expect(model.doStreamCalls).toEqual([]);
});

test("a signal on a turn the agent already ended is skipped, and sends no second end turn", async () => {
	const info = vi.spyOn(logger, "info");
	const player = await agent();
	const model = scripted([reply([endTurn("call-1", true)])]);

	await playTurn(player, context(model));

	expect(await playTurn(player, context(model))).toEqual({ ended: false, skipped: true });
	expect(model.doStreamCalls).toHaveLength(1);
	expect(lua().filter((text) => text.includes("EndTurn"))).toHaveLength(1);
	expect(info).toHaveBeenCalledWith("turn_skipped", "Player 3 already ended turn 1", { player: 3, turn: 1 });
});

test("the agent plays again once the turn number changes", async () => {
	const player = await agent();
	const model = scripted([reply([endTurn("call-1", true)]), reply([endTurn("call-2", true)])]);

	await playTurn(player, context(model));
	nextTurn();

	expect(await playTurn(player, context(model))).toEqual({ ended: true });
	expect(player.endedTurn).toBe(2);
});

test("a turn started again plays, though the agent already ended it", async () => {
	const player = await agent();
	const model = scripted([reply([endTurn("call-1", true)]), reply([endTurn("call-2", true)])]);

	await playTurn(player, context(model));

	expect(await playTurn(player, context(model), { again: true })).toEqual({ ended: true });
	expect(model.doStreamCalls).toHaveLength(2);
	expect(JSON.stringify(model.doStreamCalls[0].prompt)).not.toContain("still the same turn");
	expect(JSON.stringify(model.doStreamCalls[1].prompt)).toContain("still the same turn");
});

test("a turn that stops doesn't count as ended, so the next signal plays it", async () => {
	const player = await agent();
	const think: Content = { type: "text", text: "Hmm." };
	const model = scripted([reply([think]), reply([think]), reply([endTurn("call-1", true)])]);

	expect(await playTurn(player, context(model))).toMatchObject({ ended: false });
	expect(player.endedTurn).toBeUndefined();
	expect(await playTurn(player, context(model))).toEqual({ ended: true });
});

test("a game load during the model call cancels the turn, without a stop warning", async () => {
	const info = vi.spyOn(logger, "info");
	const warn = vi.spyOn(logger, "warn");
	const controller = new AbortController();
	const { model, started } = waitingForAbort([]);
	const turn = playTurn(await agent(), context(model), { signal: controller.signal });

	await started;
	controller.abort();

	expect(await turn).toEqual({ ended: false, cancelled: true });
	expect(info).toHaveBeenCalledWith("turn_cancelled", "Player 3's turn was cancelled, because a game loaded", { player: 3 });
	expect(warn).not.toHaveBeenCalledWith("turn_stopped", expect.anything(), expect.anything());
});

test("a game load during a tool call runs none of the reply's later calls", async () => {
	const controller = new AbortController();
	const answer = game.onCommand;

	game.onCommand = (stateIndex, text) => {
		if (text.includes("EndTurn")) {
			controller.abort();
		}

		return answer(stateIndex, text);
	};

	const plan: Content = { type: "tool-call", toolCallId: "call-2", toolName: "update_plan", input: JSON.stringify({ plan: "For the old game." }) };
	const model = scripted([reply([endTurn("call-1", false), plan])]);

	expect(await playTurn(await agent(), context(model), { signal: controller.signal })).toEqual({ ended: false, cancelled: true });
	expect(fs.existsSync(path.join(folder, "plan.md"))).toBe(false);
	expect(model.doStreamCalls).toHaveLength(1);
});

test("a game load while the state is read cancels the turn before the model is called", async () => {
	const controller = new AbortController();
	const model = scripted([]);

	controller.abort();

	expect(await playTurn(await agent(), context(model), { signal: controller.signal })).toEqual({ ended: false, cancelled: true });
	expect(model.doStreamCalls).toEqual([]);
});

test("a call the silent game doesn't answer waits for the game, and a load during the wait cancels the turn", async () => {
	const controller = new AbortController();
	const run = client.run.bind(client);

	// The game stops answering after the end turn.
	vi.spyOn(client, "run").mockImplementation((state, lua) => (lua === "return" ? Promise.reject(new TunerTimeoutError("No reply from the tuner in 100 ms")) : run(state, lua)));
	vi.spyOn(logger, "info").mockImplementation((event) => {
		if (event === "game_silent") {
			controller.abort();
		}
	});

	const plan: Content = { type: "tool-call", toolCallId: "call-2", toolName: "update_plan", input: JSON.stringify({ plan: "For the old game." }) };
	const model = scripted([reply([endTurn("call-1", false), plan])]);

	expect(await playTurn(await agent(), { ...context(model), gameWaitMs: 5 }, { signal: controller.signal })).toEqual({ ended: false, cancelled: true });
	expect(model.doStreamCalls).toHaveLength(1);
	expect(fs.existsSync(path.join(folder, "plan.md"))).toBe(false);
});

test("a failed call waits for the game, and the turn goes on once it answers", async () => {
	const info = vi.spyOn(logger, "info");
	const run = client.run.bind(client);
	let silences = 0;

	// The first check after the blocked end turn gets no answer.
	vi.spyOn(client, "run").mockImplementation((state, lua) => {
		if (lua === "return" && silences === 0) {
			silences += 1;

			return Promise.reject(new TunerTimeoutError("No reply from the tuner in 100 ms"));
		}

		return run(state, lua);
	});

	const model = scripted([reply([endTurn("call-1", false)]), reply([endTurn("call-2", true)])]);

	expect(await playTurn(await agent(), { ...context(model), gameWaitMs: 5 })).toEqual({ ended: true });
	expect(info).toHaveBeenCalledWith("game_answers", expect.anything(), { player: 3 });
});

test("the first turn moves memory from another game aside, and later turns read it as it is", async () => {
	const warn = vi.spyOn(logger, "warn");
	const player = await agent(true);

	addJournalEntry(player.memoryFolder, { turn: 40, text: "From another game." });
	await playTurn(player, context(scripted([reply([endTurn("call-1", true)])])));

	expect(player.first).toBe(false);
	expect(warn).toHaveBeenCalledWith("memory_warning", expect.stringContaining("another game"), { player: 3 });
	expect(fs.existsSync(player.memoryFolder)).toBe(false);

	addJournalEntry(player.memoryFolder, { turn: 40, text: "Kept." });
	nextTurn();

	const model = scripted([reply([endTurn("call-1", true)])]);

	await playTurn(player, context(model));

	expect(JSON.stringify(model.doStreamCalls[0].prompt)).toContain("Kept.");
	expect(fs.existsSync(player.memoryFolder)).toBe(true);
});
