// Plays an Anthropic agent's turn in the Agent SDK run mode. The SDK runs its
// own tool loop, and its hooks play each call through the shared steps.
// docs/design/core/anthropic-agent-sdk-runner.md has the design.

import fs from "node:fs";
import { type EffortLevel, type HookCallback, type HookInput, type HookJSONOutput, type Options, type PostToolUseFailureHookInput, type PostToolUseHookInput, type PreToolUseHookInput, type SDKMessage, query as sdkQuery } from "@anthropic-ai/claude-agent-sdk";
import type { ModelSetting } from "../config.js";
import { startMcpHttp } from "../mcp/http.js";
import type { ToolOutput } from "../mcp/in-process.js";
import { SERVER_NAME } from "../mcp/server.js";
import { type AgentRunner, type TurnEnd, type TurnRun, afterCall, beforeCall, startRun } from "./runner.js";

// The SDK's query(), or a fake that a test passes in.
export type QueryFunction = (params: { prompt: string; options: Options }) => AsyncIterable<SDKMessage>;

// The model and the effort the runner plays with, from config.model.
export type AgentSdkModel = Pick<ModelSetting, "id" | "effort">;

// The SDK prefixes each tool with the server's name.
const TOOL_PREFIX = `mcp__${SERVER_NAME}__`;

const OUTSIDE_TOOL = "Only the game's tools are allowed.";

const NO_END_TURN = "The model stopped without calling end_turn";

// The efforts that leave the SDK's own default.
const NO_EFFORT = new Set<AgentSdkModel["effort"]>(["", "provider-default"]);

// A turn's shared run, and the end a hook found, once the run should stop.
interface SdkRun {
	run: TurnRun;
	end?: TurnEnd;
}

type HookOutcome = Promise<HookJSONOutput>;

// The SDK ends the run after a hook that says not to go on.
const STOP: HookJSONOutput = { continue: false };

const GO_ON: HookJSONOutput = {};

export function anthropicAgentSdkRunner(model: AgentSdkModel, query: QueryFunction = sdkQuery): AgentRunner {
	return {
		runTurn: async ({ agent, message, context }, signal) => {
			const sdkRun: SdkRun = { run: startRun(agent, context, signal) };
			const end = await runQuery(query, model, sdkRun, message);

			return { end, spend: sdkRun.run.tally.spend };
		},
	};
}

// Each turn serves the agent's tools on a free port, and closes it after, so
// no port stays open between turns.
async function runQuery(query: QueryFunction, model: AgentSdkModel, sdkRun: SdkRun, message: string): Promise<TurnEnd> {
	const { agent, signal } = sdkRun.run;
	const http = await startMcpHttp(0, agent.toolContext);

	if (http === undefined) {
		return { failed: "The game's tools couldn't be served to the Agent SDK", stopRun: false };
	}

	const abortController = new AbortController();
	const abort = (): void => abortController.abort();

	// The signal may abort while the tools start, before the listener.
	signal.addEventListener("abort", abort, { once: true });

	if (signal.aborted) {
		abort();
	}

	try {
		return await readMessages(query({ prompt: message, options: queryOptions(sdkRun, model, http.url, abortController) }), sdkRun);
	} catch (error) {
		return signal.aborted ? { aborted: true } : { failed: `The Agent SDK failed: ${String(error)}`, stopRun: false };
	} finally {
		signal.removeEventListener("abort", abort);
		abortController.abort();
		await http.close();
	}
}

// The options keep the SDK to the bridge's tools and prompt, as
// docs/design/core/run-modes.md#parity-check says.
function queryOptions(sdkRun: SdkRun, { id, effort }: AgentSdkModel, url: string, abortController: AbortController): Options {
	const { agent } = sdkRun.run;

	// The memory folder holds no AGENTS.md, which the SDK's plugin would load.
	fs.mkdirSync(agent.memoryFolder, { recursive: true });

	return {
		systemPrompt: agent.system,
		tools: [],
		mcpServers: { [SERVER_NAME]: { type: "http", url } },
		strictMcpConfig: true,
		settingSources: [],
		cwd: agent.memoryFolder,
		persistSession: false,
		permissionMode: "dontAsk",
		abortController,
		hooks: {
			PreToolUse: [{ hooks: [hook(sdkRun, beforeHook)] }],
			PostToolUse: [{ hooks: [hook(sdkRun, afterHook)] }],
			PostToolUseFailure: [{ hooks: [hook(sdkRun, afterFailureHook)] }],
		},
		...(id === "" ? {} : { model: id }),
		// The picker offers only the efforts the model takes.
		...(NO_EFFORT.has(effort) ? {} : { effort: effort as EffortLevel }),
	};
}

// Each hook is registered for one event, so its input is that event's.
function hook<Input extends HookInput>(sdkRun: SdkRun, handle: (sdkRun: SdkRun, input: Input) => HookOutcome): HookCallback {
	return (input) => handle(sdkRun, input as Input);
}

// The run ends at the turn's end, so a result with no end means the model
// stopped on its own.
async function readMessages(messages: AsyncIterable<SDKMessage>, sdkRun: SdkRun): Promise<TurnEnd> {
	for await (const message of messages) {
		if (sdkRun.end !== undefined) {
			break;
		}

		if (message.type === "result") {
			return message.subtype === "success" ? { failed: NO_END_TURN, stopRun: false } : { failed: `The Agent SDK stopped: ${message.errors.join("; ")}`, stopRun: false };
		}
	}

	return sdkRun.end ?? (sdkRun.run.signal.aborted ? { aborted: true } : { failed: NO_END_TURN, stopRun: false });
}

// Only the bridge's tools run. After an abort, the call is denied too.
function beforeHook(sdkRun: SdkRun, input: PreToolUseHookInput): HookOutcome {
	const aborted = beforeCall(sdkRun.run);

	if (aborted !== undefined) {
		sdkRun.end = aborted;

		return Promise.resolve({ ...STOP, hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "The turn was cancelled." } });
	}

	const allowed = input.tool_name.startsWith(TOOL_PREFIX);

	return Promise.resolve({
		hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: allowed ? "allow" : "deny", ...(allowed ? {} : { permissionDecisionReason: OUTSIDE_TOOL }) },
	});
}

function afterHook(sdkRun: SdkRun, input: PostToolUseHookInput): HookOutcome {
	return playAfterCall(sdkRun, input.tool_name, input.tool_input, { text: "", isError: false });
}

function afterFailureHook(sdkRun: SdkRun, input: PostToolUseFailureHookInput): HookOutcome {
	return playAfterCall(sdkRun, input.tool_name, input.tool_input, { text: input.error, isError: true });
}

// The shared step logs the call and finds the end it brings, which stops the
// run.
async function playAfterCall(sdkRun: SdkRun, tool: string, input: unknown, output: ToolOutput): HookOutcome {
	const end = await afterCall(sdkRun.run, tool.slice(TOOL_PREFIX.length), input, output);

	if (end === undefined) {
		return GO_ON;
	}

	sdkRun.end = end;

	return STOP;
}
