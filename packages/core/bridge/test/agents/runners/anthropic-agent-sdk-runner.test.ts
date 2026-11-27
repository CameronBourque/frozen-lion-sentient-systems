// Tests for the Anthropic Agent SDK runner: each turn plays through playTurn,
// with a fake query() that calls the tools over the runner's MCP server.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { SDKMessage } from "@anthropic-ai/claude-agent-sdk";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { anthropicAgentSdkRunner } from "../../../src/agents/runners/anthropic-agent-sdk-runner.js";
import { type LoopContext, playTurn } from "../../../src/agents/loop.js";
import { noSpend } from "../../../src/agents/spend.js";
import { DEFAULT_LIMITS, type Limits, type ModelSetting, NO_MODEL } from "../../../src/config.js";
import { Logger } from "../../../src/log.js";
import * as http from "../../../src/mcp/http.js";
import { type TunerClient, TunerTimeoutError } from "../../../src/tuner/client.js";
import { answerStash } from "../../mcp/tools.js";
import { MINIMAL_STATE } from "../../state/minimal-state.js";
import { type FakeGame, startGame } from "../../tuner/fake-game.js";
import { SYSTEM, testAgent } from "../agent.js";
import { type FakeCall, type FakeQuery, type FakeScript, fakeQuery } from "./fake-agent-sdk-query.js";

const REASON = "Nothing left to do.";

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

function context(fake: FakeQuery, limits: Partial<Limits> = {}, model: ModelSetting = NO_MODEL): LoopContext {
	return {
		client,
		logger,
		runner: anthropicAgentSdkRunner(model, fake.query),
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

	const [{ prompt, options }] = fake.params;

	expect(prompt).toContain("turn");
	expect(options).toMatchObject({ systemPrompt: SYSTEM, tools: [], strictMcpConfig: true, settingSources: [], cwd: folder, persistSession: false, permissionMode: "dontAsk", model: "claude-opus-5-5", effort: "high" });
	expect(fs.existsSync(folder)).toBe(true);
});

test("a blank model and the provider's default effort leave the SDK's defaults", async () => {
	endTurnGoesThrough();

	const fake = fakeQuery({ calls: [END_TURN] });

	await playTurn(await testAgent(client, logger, folder), context(fake, {}, { ...NO_MODEL, effort: "provider-default" }));

	expect(fake.params[0].options).not.toHaveProperty("model");
	expect(fake.params[0].options).not.toHaveProperty("effort");
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

	await vi.waitFor(() => expect(fake.params).toHaveLength(1));
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

test("a model that stops without an end turn stops the turn, and sends no end turn", async () => {
	const warn = vi.spyOn(logger, "warn");
	const { result } = await play({ calls: [RESEARCH] });

	expect(result).toEqual({ ended: false, reason: "The model stopped without calling end_turn" });
	expect(warn).toHaveBeenCalledWith("turn_stopped", expect.stringContaining("without calling end_turn"), expect.anything());
	expect(forcedEnds()).toEqual([]);
});

test("a run with no result message stops the turn too", async () => {
	const fake = fakeQuery({ calls: [] });
	const empty: FakeQuery = { ...fake, query: async function* () {} };

	expect(await playTurn(await testAgent(client, logger, folder), context(empty))).toEqual({ ended: false, reason: "The model stopped without calling end_turn" });
});

test("an SDK error result stops the turn with its errors", async () => {
	const failed = { type: "result", subtype: "error_during_execution", errors: ["Overloaded", "Try again"] } as unknown as SDKMessage;
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
	expect(fake.params).toEqual([]);
});
