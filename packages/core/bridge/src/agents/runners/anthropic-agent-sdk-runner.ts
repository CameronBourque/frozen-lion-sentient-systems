// Plays an Anthropic agent's turn in the Agent SDK run mode. The SDK runs its
// own tool loop, and its hooks play each call through the shared steps.
// docs/design/core/anthropic-agent-sdk-runner.md has the design.

import fs from "node:fs";
import type { ApiKeySource, EffortLevel, HookCallback, HookInput, HookJSONOutput, Options, PostToolUseFailureHookInput, PostToolUseHookInput, PreToolUseHookInput, SDKAssistantMessage, SDKMessage, SDKResultMessage, SDKSystemMessage, SDKUserMessage } from "@anthropic-ai/claude-agent-sdk";
import { query as sdkQuery } from "@anthropic-ai/claude-agent-sdk";
import type { ModelSetting } from "../../config.js";
import { startMcpHttp } from "../../mcp/http.js";
import type { ToolOutput } from "../../mcp/in-process.js";
import type { Usage } from "../../model/client.js";
import { logModelCall } from "../../model/usage.js";
import { SERVER_NAME } from "../../mcp/server.js";
import { type AgentRunner, NUDGE, type TurnEnd, type TurnRun, afterCall, beforeCall, countNoToolCall, spendCall, startRun } from "./shared.js";

// The SDK's query(), or a fake that a test passes in.
export type QueryFunction = (params: { prompt: AsyncIterable<SDKUserMessage>; options: Options }) => AsyncIterable<SDKMessage>;

// The model and the effort the runner plays with, from config.model, and the
// environment the SDK runs in, which holds only the sign-in the user picked.
export type AgentSdkModel = Pick<ModelSetting, "id" | "effort"> & { env: Options["env"] };

// The SDK prefixes each tool with the server's name.
const TOOL_PREFIX = `mcp__${SERVER_NAME}__`;

const OUTSIDE_TOOL = "Only the game's tools are allowed.";

const NO_END_TURN = "The model stopped without calling end_turn";

// How long the runner reads on after a hook stops the run, for the result
// that holds the round's output.
const RESULT_WAIT_MS = 5000;

// The efforts that leave the SDK's own default.
const NO_EFFORT = new Set<AgentSdkModel["effort"]>(["", "provider-default"]);

// The messages the runner sends into the session: the turn message, and a
// nudge after each reply with no tool call.
interface Prompt {
	messages: AsyncIterable<SDKUserMessage>;
	send: (text: string) => void;
	close: () => void;
}

// A turn's shared run, and the end a hook or a spend found, once the run
// should stop. stopped is set when a hook stopped the SDK, which then sends a
// last result, and waitForResult starts the timer that ends a wait for it
// that runs long. counted holds the model calls already counted, and the round
// holds the usage since the last result, whose output comes with the result.
interface SdkRun {
	run: TurnRun;
	prompt: Prompt;
	end?: TurnEnd;
	stopped?: boolean;
	waitForResult: () => void;
	counted: Set<string>;
	round: Usage;
	outputTokens: number;
}

type HookOutcome = Promise<HookJSONOutput>;

// The SDK ends the run after a hook that says not to go on.
const STOP: HookJSONOutput = { continue: false };

const GO_ON: HookJSONOutput = {};

// resultWaitMs is shorter in tests.
export function anthropicAgentSdkRunner(model: AgentSdkModel, query: QueryFunction = sdkQuery, resultWaitMs = RESULT_WAIT_MS): AgentRunner {
	return {
		runTurn: async ({ agent, message, context }, signal) => {
			const sdkRun: SdkRun = { run: startRun(agent, context, signal), prompt: prompt(message), waitForResult: () => undefined, counted: new Set(), round: noUsage(), outputTokens: 0 };
			const end = await runQuery(query, model, sdkRun, resultWaitMs);

			return { end, spend: sdkRun.run.tally.spend };
		},
	};
}

// Each turn serves the agent's tools on a free port, and closes it after, so
// no port stays open between turns.
async function runQuery(query: QueryFunction, model: AgentSdkModel, sdkRun: SdkRun, resultWaitMs: number): Promise<TurnEnd> {
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

	let wait: NodeJS.Timeout | undefined;

	sdkRun.waitForResult = () => {
		wait ??= setTimeout(abort, resultWaitMs);
	};

	try {
		return await readMessages(query({ prompt: sdkRun.prompt.messages, options: queryOptions(sdkRun, model, http.url, abortController) }), sdkRun);
	} catch (error) {
		return signal.aborted ? { aborted: true } : { failed: `The Agent SDK failed: ${String(error)}`, stopRun: false };
	} finally {
		clearTimeout(wait);
		signal.removeEventListener("abort", abort);
		sdkRun.prompt.close();
		abortController.abort();
		await http.close();
	}
}

// The options keep the SDK to the bridge's tools and prompt, as
// docs/design/core/run-modes.md#parity-check says.
function queryOptions(sdkRun: SdkRun, { id, effort, env }: AgentSdkModel, url: string, abortController: AbortController): Options {
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
		env,
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

// Reads the session until the turn's end. Each result is a reply with no tool
// call, which counts as a failure and gets the nudge, as in the bridge's own
// loop. After a hook stops the run, such as at an end_turn, it reads on to the
// last result, so the round's output logs and counts.
async function readMessages(messages: AsyncIterable<SDKMessage>, sdkRun: SdkRun): Promise<TurnEnd> {
	try {
		for await (const message of messages) {
			if (sdkRun.end === undefined) {
				sdkRun.end = readMessage(sdkRun, message);
			} else if (message.type === "result") {
				countRound(sdkRun, message);
			}

			if (sdkRun.end !== undefined && (sdkRun.stopped !== true || message.type === "result")) {
				break;
			}
		}
	} catch (error) {
		// An abort after the end leaves the end as it was.
		if (sdkRun.end === undefined) {
			throw error;
		}
	}

	return sdkRun.end ?? (sdkRun.run.signal.aborted ? { aborted: true } : { failed: NO_END_TURN, stopRun: false });
}

function readMessage(sdkRun: SdkRun, message: SDKMessage): TurnEnd | undefined {
	if (message.type === "system" && message.subtype === "init") {
		logSession(sdkRun, message);

		return undefined;
	}

	if (message.type === "assistant") {
		return countCall(sdkRun, message);
	}

	if (message.type !== "result") {
		return undefined;
	}

	const counted = countRound(sdkRun, message);

	if (message.subtype !== "success") {
		return { failed: `The Agent SDK stopped: ${message.errors.join("; ")}`, stopRun: false };
	}

	const end = counted ?? countNoToolCall(sdkRun.run);

	if (end === undefined) {
		sdkRun.prompt.send(NUDGE);
	}

	return end;
}

// The session's first message says how the SDK signed in and which tools it
// has, which shows the pick and the options took.
function logSession({ run }: SdkRun, message: SDKSystemMessage): void {
	const { model, tools } = message;
	const builtIn = tools.filter((tool) => !tool.startsWith(TOOL_PREFIX));
	const signIn = signInName(message.apiKeySource);

	run.context.logger.debug("sdk_session", `The Agent SDK signed in with ${signIn} on ${model}, with ${tools.length} tools, ${builtIn.length} of them built in`, { player: run.agent.playerID, signIn, model, builtIn });
}

// The SDK's label in the picker's words. The log gets only the bridge's own
// strings, since a scanner reads any field named for a key as a secret, though
// the label never holds the key.
function signInName(source: ApiKeySource): string {
	if (source === "ANTHROPIC_API_KEY") {
		return "api-key";
	}

	// With no key, the SDK uses the login. No bridge sign-in gives the others,
	// since the SDK loads no settings.
	return source === "none" || source === "oauth" ? "plan" : "other";
}

// Each model call counts against the spending limits as it comes, so a long
// round stops at a limit. Its output is a placeholder until the result, and
// the SDK may send one call in several messages.
function countCall(sdkRun: SdkRun, { message }: SDKAssistantMessage): TurnEnd | undefined {
	if (sdkRun.counted.has(message.id)) {
		return undefined;
	}

	sdkRun.counted.add(message.id);

	const cacheReadTokens = message.usage.cache_read_input_tokens ?? 0;
	const cacheWriteTokens = message.usage.cache_creation_input_tokens ?? 0;
	// The bridge counts every input token, and Anthropic only the uncached.
	const usage: Usage = { inputTokens: message.usage.input_tokens + cacheReadTokens + cacheWriteTokens, cacheReadTokens, cacheWriteTokens, outputTokens: 0 };

	addUsage(sdkRun.round, usage);

	return spendCall(sdkRun.run, usage);
}

// The result's output is the session's total so far, so the round's output is
// what it added. The round logs as one model call.
function countRound(sdkRun: SdkRun, { usage }: SDKResultMessage): TurnEnd | undefined {
	const outputTokens = usage.output_tokens - sdkRun.outputTokens;
	const round = { ...sdkRun.round, outputTokens };

	sdkRun.outputTokens = usage.output_tokens;
	sdkRun.round = noUsage();
	logModelCall(sdkRun.run.context.logger, sdkRun.run.context.model, round);

	return spendCall(sdkRun.run, { ...noUsage(), outputTokens });
}

function noUsage(): Usage {
	return { inputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 0 };
}

function addUsage(total: Usage, usage: Usage): void {
	total.inputTokens += usage.inputTokens;
	total.cacheReadTokens += usage.cacheReadTokens;
	total.cacheWriteTokens += usage.cacheWriteTokens;
}

// The session stays open while the prompt does, so the nudge goes into the
// same context.
function prompt(first: string): Prompt {
	const waiting = [first];
	let wake: (() => void) | undefined;
	let closed = false;

	async function* messages(): AsyncGenerator<SDKUserMessage> {
		for (;;) {
			const text = waiting.shift();

			if (text !== undefined) {
				yield { type: "user", message: { role: "user", content: text }, parent_tool_use_id: null };
				continue;
			}

			if (closed) {
				return;
			}

			await new Promise<void>((resolve) => {
				wake = resolve;
			});
		}
	}

	const wakeUp = (): void => {
		wake?.();
		wake = undefined;
	};

	return {
		messages: messages(),
		send: (text) => {
			waiting.push(text);
			wakeUp();
		},
		close: () => {
			closed = true;
			wakeUp();
		},
	};
}

// Only the bridge's tools run. After an abort, the call is denied too.
function beforeHook(sdkRun: SdkRun, input: PreToolUseHookInput): HookOutcome {
	const aborted = beforeCall(sdkRun.run);

	if (aborted !== undefined) {
		stopRun(sdkRun, aborted);

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

	stopRun(sdkRun, end);

	return STOP;
}

// A hook that stops the run waits for the SDK's last result.
function stopRun(sdkRun: SdkRun, end: TurnEnd): void {
	sdkRun.end = end;
	sdkRun.stopped = true;
	sdkRun.waitForResult();
}
