// Tests for the Anthropic Agent SDK runner: each turn plays through playTurn,
// with a fake query() that calls the tools over the runner's MCP server.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { SDKMessage } from "@anthropic-ai/claude-agent-sdk";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { anthropicAgentSdkRunner } from "../../../src/agents/runners/anthropic-agent-sdk-runner.js";
import { type LoopContext, playTurn } from "../../../src/agents/loop.js";
import { NUDGE } from "../../../src/agents/runners/shared.js";
import { noSpend } from "../../../src/agents/spend.js";
import { DEFAULT_LIMITS, type Limits, type ModelSetting, NO_MODEL } from "../../../src/config.js";
import { Logger } from "../../../src/log.js";
import * as http from "../../../src/mcp/http.js";
import { type TunerClient, TunerTimeoutError } from "../../../src/tuner/client.js";
import { answerStash } from "../../mcp/tools.js";
import { MINIMAL_STATE } from "../../state/minimal-state.js";
import { type FakeGame, startGame } from "../../tuner/fake-game.js";
import { SYSTEM, testAgent } from "../agent.js";
import { type FakeCall, type FakeQuery, type FakeScript, INIT, SUCCESS, fakeQuery } from "./fake-agent-sdk-query.js";

const REASON = "Nothing left to do.";

// The environment the mode builds for the sign-in the user picked.
const ENV = { PATH: "/opt/game" };

let game: FakeGame;
let client: TunerClient;
let root: string;
let folder: string;
let logger: Logger;

beforeEach(async () => {
	({ game, client } = await startGame());
	root = fs.mkdtempSync(path.join(os.tmpdir(), "anthropic-agent-sdk-runner-"));
	folder = path.join(root, "player-3");
	logger = new Logger("error");
	answerStash(game, {
		"SentientSystems_GetState(3)": MINIMAL_STATE,
		"SentientSystems_EndTurn(3, false)": { ok: false, reason: "Choose a research." },
		"SentientSystems_EndTurn(3, true)": { ok: true },
	});
});

afterEach(() => {
	vi.restoreAllMocks();
	fs.rmSync(root, { recursive: true, force: true, maxRetries: 3 });
});

// A short wait for the last result, so a test of a run that never sends it
// ends quickly.
const SHORT_RESULT_WAIT_MS = 50;

function context(fake: FakeQuery, limits: Partial<Limits> = {}, model: ModelSetting = NO_MODEL): LoopContext {
	return {
		client,
		logger,
		runner: anthropicAgentSdkRunner({ id: model.id, effort: model.effort, env: ENV }, fake.query, SHORT_RESULT_WAIT_MS),
		model,
		journalEntries: 5,
		limits: { ...DEFAULT_LIMITS, ...limits },
		runSpend: noSpend(),
		now: () => new Date("2026-11-27T12:00:00Z"),
	};
}

async function play(script: FakeScript, limits: Partial<Limits> = {}, signal?: AbortSignal): Promise<{ fake: FakeQuery; result: Awaited<ReturnType<typeof playTurn>> }> {
	const fake = fakeQuery(script);
	const result = await playTurn(await testAgent(client, logger, folder), context(fake, limits), { signal });

	return { fake, result };
}

const END_TURN: FakeCall = { name: "end_turn", input: { reason: REASON } };

const RESEARCH: FakeCall = { name: "set_research", input: { reason: REASON, type: "TECH_MINING" } };

const PLAN: FakeCall = { name: "update_plan", input: { plan: "Too late." } };

function lua(): string[] {
	return game.commands.map(({ lua: text }) => text);
}

function forcedEnds(): string[] {
	return lua().filter((text) => text.includes("SentientSystems_EndTurn(3, true)"));
}

// Lets the end turn go through.
function endTurnGoesThrough(): void {
	answerStash(game, {
		"SentientSystems_GetState(3)": MINIMAL_STATE,
		"SentientSystems_EndTurn(3, false)": { ok: true },
	});
}

test("the query keeps to the bridge's prompt and tools, and runs in the memory folder", async () => {
	endTurnGoesThrough();

	const fake = fakeQuery({ calls: [END_TURN] });
	const setting: ModelSetting = { ...NO_MODEL, mode: "agent-sdk", provider: "anthropic", id: "claude-opus-5-5", effort: "high" };

	expect(await playTurn(await testAgent(client, logger, folder), context(fake, {}, setting))).toEqual({ ended: true });

	const [options] = fake.options;
	const [prompt] = fake.prompts;

	expect(prompt).toContain("turn");
	expect(options).toMatchObject({ systemPrompt: SYSTEM, tools: [], strictMcpConfig: true, settingSources: [], cwd: folder, persistSession: false, permissionMode: "dontAsk", env: ENV, model: "claude-opus-5-5", effort: "high" });
	expect(fs.existsSync(folder)).toBe(true);
});

test("a blank model and the provider's default effort leave the SDK's defaults", async () => {
	endTurnGoesThrough();

	const fake = fakeQuery({ calls: [END_TURN] });

	await playTurn(await testAgent(client, logger, folder), context(fake, {}, { ...NO_MODEL, effort: "provider-default" }));

	expect(fake.options[0]).not.toHaveProperty("model");
	expect(fake.options[0]).not.toHaveProperty("effort");
});

test("the session's sign-in, model, and built-in tools log at the debug level", async () => {
	endTurnGoesThrough();

	const debug = vi.spyOn(logger, "debug");

	await play({ calls: [END_TURN] });

	expect(debug).toHaveBeenCalledWith("sdk_session", "The Agent SDK signed in with api-key on claude-haiku-5-5, with 2 tools, 0 of them built in", { player: 3, signIn: "api-key", model: "claude-haiku-5-5", builtIn: [] });
});

test.each([
	["none", "plan"],
	["oauth", "plan"],
	["apiKeyHelper", "other"],
])("the SDK's %s sign-in logs as %s", async (source, signIn) => {
	endTurnGoesThrough();

	const debug = vi.spyOn(logger, "debug");

	await play({ calls: [END_TURN], init: { ...INIT, apiKeySource: source } as SDKMessage });

	expect(debug).toHaveBeenCalledWith("sdk_session", expect.stringContaining(`signed in with ${signIn} on`), expect.objectContaining({ signIn }));
});

test("an end turn that goes through ends the turn, and the calls after it don't run", async () => {
	endTurnGoesThrough();

	const { fake, result } = await play({ calls: [END_TURN, PLAN] });

	expect(result).toEqual({ ended: true });
	expect(fake.called).toEqual(["end_turn"]);
	expect(fs.existsSync(path.join(folder, "plan.md"))).toBe(false);
});

test("a blocked end turn goes back to the model, which acts and tries again", async () => {
	const debug = vi.spyOn(logger, "debug");
	const answer = game.onCommand;
	let ends = 0;

	// The second end turn goes through.
	game.onCommand = (stateIndex, text) => {
		if (text.includes("EndTurn(3, false)") && ++ends === 2) {
			endTurnGoesThrough();

			return game.onCommand(stateIndex, text);
		}

		return answer(stateIndex, text);
	};

	const { fake, result } = await play({ calls: [END_TURN, PLAN, END_TURN] });

	expect(result).toEqual({ ended: true });
	expect(fake.called).toEqual(["end_turn", "update_plan", "end_turn"]);
	expect(debug).toHaveBeenCalledWith("tool_call", "end_turn: failed: Choose a research.", expect.objectContaining({ tool: "end_turn", ok: false, failure: "Choose a research." }));
	expect(debug).toHaveBeenCalledWith("tool_call", "update_plan: done", expect.objectContaining({ tool: "update_plan", ok: true, input: PLAN.input }));
});

test("a tool that isn't the bridge's is denied and never runs", async () => {
	endTurnGoesThrough();

	const { fake, result } = await play({ calls: [{ name: "Bash", outside: true }, END_TURN] });

	expect(result).toEqual({ ended: true });
	expect(fake.called).toEqual(["end_turn"]);
});

test("the actions per turn limit ends the turn with force, and the later calls don't run", async () => {
	const { fake, result } = await play({ calls: [RESEARCH, PLAN] }, { actionsPerTurn: 1 });

	expect(result).toEqual({ ended: true });
	expect(fake.called).toEqual(["set_research"]);
	expect(forcedEnds()).toHaveLength(1);
});

test("failed actions in a row past the retries limit end the turn with force", async () => {
	const { fake, result } = await play({ calls: [END_TURN, END_TURN, END_TURN] }, { retriesPerAction: 1 });

	expect(result).toEqual({ ended: true });
	expect(fake.called).toHaveLength(2);
	expect(forcedEnds()).toHaveLength(1);
});

test("a model that never answers is stopped at the time limit, and the turn ends with force", async () => {
	const { result } = await play({ calls: [], hang: true }, { turnMinutes: 0.0001 });

	expect(result).toEqual({ ended: true });
	expect(forcedEnds()).toHaveLength(1);
});

test("a stop while the model works cancels the turn, and sends no end turn", async () => {
	const controller = new AbortController();
	const fake = fakeQuery({ calls: [], hang: true });
	const turn = playTurn(await testAgent(client, logger, folder), context(fake), { signal: controller.signal });

	await vi.waitFor(() => expect(fake.options).toHaveLength(1));
	controller.abort("stop");

	expect(await turn).toEqual({ ended: false, cancelled: true });
	expect(lua().some((text) => text.includes("EndTurn"))).toBe(false);
});

test("a cancel while the tools start cancels the turn before any call", async () => {
	const controller = new AbortController();
	const start = http.startMcpHttp;

	vi.spyOn(http, "startMcpHttp").mockImplementation(async (port, toolContext) => {
		const served = await start(port, toolContext);

		controller.abort();

		return served;
	});

	const { fake, result } = await play({ calls: [END_TURN], hang: true }, {}, controller.signal);

	expect(result).toEqual({ ended: false, cancelled: true });
	expect(fake.called).toEqual([]);
});

test("a call after a cancel is denied, and the run ends", async () => {
	const controller = new AbortController();
	const answer = game.onCommand;

	game.onCommand = (stateIndex, text) => {
		if (text.includes("TECH_MINING")) {
			controller.abort();
		}

		return answer(stateIndex, text);
	};

	const { fake, result } = await play({ calls: [RESEARCH, PLAN] }, {}, controller.signal);

	expect(result).toEqual({ ended: false, cancelled: true });
	expect(fake.called).toEqual(["set_research"]);
	expect(fs.existsSync(path.join(folder, "plan.md"))).toBe(false);
});

test("a failed call waits for a silent game, and a load during the wait cancels the turn", async () => {
	const controller = new AbortController();
	const run = client.run.bind(client);

	vi.spyOn(client, "run").mockImplementation((state, text) => (text === "return" ? Promise.reject(new TunerTimeoutError("No reply from the tuner in 100 ms")) : run(state, text)));
	vi.spyOn(logger, "info").mockImplementation((event) => {
		if (event === "game_silent") {
			controller.abort();
		}
	});

	const fake = fakeQuery({ calls: [END_TURN, PLAN] });
	const result = await playTurn(await testAgent(client, logger, folder), { ...context(fake), gameWaitMs: 5 }, { signal: controller.signal });

	expect(result).toEqual({ ended: false, cancelled: true });
	expect(fake.called).toEqual(["end_turn"]);
});

test("a reply with no tool call gets the nudge in the same session, and the model acts", async () => {
	endTurnGoesThrough();

	const { fake, result } = await play({ calls: [], rounds: [{ calls: [END_TURN] }] });

	expect(result).toEqual({ ended: true });
	expect(fake.prompts).toEqual([expect.stringContaining("turn") as unknown, NUDGE]);
	expect(fake.options).toHaveLength(1);
});

test("replies with no tool call count as failures, and past the retries limit the turn ends with force", async () => {
	const { fake, result } = await play({ calls: [] }, { retriesPerAction: 1 });

	expect(result).toEqual({ ended: true });
	expect(fake.prompts).toHaveLength(2);
	expect(forcedEnds()).toHaveLength(1);
});

test("a run with no result message stops the turn too", async () => {
	const fake = fakeQuery({ calls: [] });
	const empty: FakeQuery = { ...fake, query: async function* () {} };

	expect(await playTurn(await testAgent(client, logger, folder), context(empty))).toEqual({ ended: false, reason: "The model stopped without calling end_turn" });
});

test("an SDK error result stops the turn with its errors", async () => {
	const failed = { type: "result", subtype: "error_during_execution", errors: ["Overloaded", "Try again"], usage: { output_tokens: 0 } } as unknown as SDKMessage;
	const { result } = await play({ calls: [], result: failed });

	expect(result).toEqual({ ended: false, reason: "The Agent SDK stopped: Overloaded; Try again" });
});

test("an SDK that throws stops the turn with why", async () => {
	const { result } = await play({ calls: [], throws: new Error("spawn claude ENOENT") });

	expect(result).toEqual({ ended: false, reason: "The Agent SDK failed: Error: spawn claude ENOENT" });
});

test("a port the tools can't be served on stops the turn before the SDK starts", async () => {
	vi.spyOn(http, "startMcpHttp").mockResolvedValue(undefined);

	const { fake, result } = await play({ calls: [END_TURN] });

	expect(result).toEqual({ ended: false, reason: "The game's tools couldn't be served to the Agent SDK" });
	expect(fake.options).toEqual([]);
});

// One model call, which the SDK sends as two messages with the same id.
function modelCall(id: string, input: number, cacheRead: number, cacheWrite: number): SDKMessage[] {
	const message = { type: "assistant", message: { id, usage: { input_tokens: input, cache_read_input_tokens: cacheRead, cache_creation_input_tokens: cacheWrite, output_tokens: 1 } } } as unknown as SDKMessage;

	return [message, message];
}

// The result's output is the session's total so far.
function resultWithOutput(outputTokens: number): SDKMessage {
	return { ...SUCCESS, usage: { output_tokens: outputTokens } } as SDKMessage;
}

test("each model call counts once against the spend, and each round logs as one call with its output", async () => {
	endTurnGoesThrough();

	const decision = vi.spyOn(logger, "decision");
	const fake = fakeQuery({ assistant: modelCall("m1", 100, 20, 5), calls: [], result: resultWithOutput(40), rounds: [{ assistant: modelCall("m2", 10, 0, 0), calls: [END_TURN], result: resultWithOutput(70) }] });
	const turn = context(fake);

	expect(await playTurn(await testAgent(client, logger, folder), turn)).toEqual({ ended: true });
	expect(turn.runSpend.tokens).toBe(125 + 40 + 10 + 30);
	expect(decision).toHaveBeenCalledWith("model_call", ": 125 input (20 read from the cache, 5 written to it) and 40 output tokens", expect.anything());
});

test("the round an end turn stops still logs and counts its output, from the SDK's last result", async () => {
	endTurnGoesThrough();

	const decision = vi.spyOn(logger, "decision");
	const fake = fakeQuery({ assistant: modelCall("m1", 100, 0, 0), calls: [END_TURN], result: resultWithOutput(60) });
	const turn = context(fake);

	expect(await playTurn(await testAgent(client, logger, folder), turn)).toEqual({ ended: true });
	expect(turn.runSpend.tokens).toBe(160);
	expect(decision).toHaveBeenCalledWith("model_call", ": 100 input and 60 output tokens", expect.anything());
});

test("a run that sends no last result after an end turn still ends the turn, after the wait", async () => {
	endTurnGoesThrough();

	const fake = fakeQuery({ assistant: modelCall("m1", 100, 0, 0), calls: [END_TURN], noLastResult: true });
	const turn = context(fake);

	expect(await playTurn(await testAgent(client, logger, folder), turn)).toEqual({ ended: true });
	expect(turn.runSpend.tokens).toBe(100);
});

test("the output a round adds is the change in the session's total", async () => {
	const fake = fakeQuery({ calls: [], result: resultWithOutput(40), rounds: [{ calls: [], result: resultWithOutput(70) }] });
	const turn = context(fake, { retriesPerAction: 1 });

	await playTurn(await testAgent(client, logger, folder), turn);

	expect(turn.runSpend.tokens).toBe(70);
});

test("a turn at its token limit ends with force, and the round's calls don't run", async () => {
	const { fake, result } = await play({ assistant: modelCall("m1", 100, 0, 0), calls: [RESEARCH] }, { tokensPerTurn: 100 });

	expect(result).toEqual({ ended: true });
	expect(fake.called).toEqual([]);
	expect(forcedEnds()).toHaveLength(1);
});

test("a run at its token limit stops the run without an end turn", async () => {
	const { result } = await play({ assistant: modelCall("m1", 100, 0, 0), calls: [RESEARCH] }, { tokensPerRun: 50 });

	expect(result).toEqual({ ended: false, reason: "The run reached the tokens per run limit of 50", stopRun: true });
	expect(forcedEnds()).toEqual([]);
});
