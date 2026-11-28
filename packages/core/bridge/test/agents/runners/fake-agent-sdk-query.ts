// A fake of the Agent SDK's query(). It plays a script of tool calls through
// the hooks it's given and the MCP server in its options, as the SDK would.

import type { HookEvent, HookInput, Options, SDKMessage, SyncHookJSONOutput } from "@anthropic-ai/claude-agent-sdk";
import { Client, StreamableHTTPClientTransport } from "@modelcontextprotocol/client";
import type { QueryFunction } from "../../../src/agents/runners/anthropic-agent-sdk-runner.js";
import { callTool } from "../../../src/mcp/in-process.js";
import { SERVER_NAME } from "../../../src/mcp/server.js";

// outside names a tool that isn't the bridge's, such as a built-in one.
export interface FakeCall {
	name: string;
	input?: Record<string, unknown>;
	outside?: true;
}

// One reply round: the assistant messages it sends, the calls it makes, and
// the result it ends with.
export interface FakeRound {
	assistant?: SDKMessage[];
	calls?: FakeCall[];
	result?: SDKMessage;
}

// The first round plays on the turn message, and each of rounds on the next
// prompt, such as a nudge. A prompt past the last round gets a round with no
// call. hang waits for the abort after the first round's calls, as a model
// that never answers, and throws ends the run in place of its result.
// noLastResult waits for the abort after a hook stops the run, in place of
// the last result.
export interface FakeScript extends FakeRound {
	rounds?: FakeRound[];
	hang?: true;
	throws?: Error;
	noLastResult?: true;
}

export interface FakeQuery {
	query: QueryFunction;
	options: Options[];
	// The text of each prompt the run read.
	prompts: string[];
	// The tools the run called, by the bridge's name.
	called: string[];
}

const INIT = { type: "system", subtype: "init" } as SDKMessage;

export const SUCCESS = { type: "result", subtype: "success", usage: { output_tokens: 0 } } as SDKMessage;

export function fakeQuery(script: FakeScript): FakeQuery {
	const fake: FakeQuery = { query: (params) => play(fake, script, params), options: [], prompts: [], called: [] };

	return fake;
}

async function* play(fake: FakeQuery, script: FakeScript, { prompt, options }: Parameters<QueryFunction>[0]): AsyncGenerator<SDKMessage> {
	fake.options.push(options);

	const prompts = prompt[Symbol.asyncIterator]();

	// Returns false once the runner closes the prompt.
	const readPrompt = async (): Promise<boolean> => {
		const next = await prompts.next();

		if (next.done === true) {
			return false;
		}

		fake.prompts.push(next.value.message.content as string);

		return true;
	};

	const { url } = options.mcpServers?.[SERVER_NAME] as { url: string };
	const client = new Client({ name: "fake-sdk", version: "1.0.0" });

	await client.connect(new StreamableHTTPClientTransport(new URL(url)));
	await readPrompt();

	try {
		const rounds: FakeRound[] = [script, ...(script.rounds ?? [])];

		yield INIT;

		for (let index = 0; ; index += 1) {
			const round = rounds[index] ?? {};

			yield* round.assistant ?? [];

			for (const [call, fakeCall] of (round.calls ?? []).entries()) {
				// A hook that ends the run still gets the SDK's result.
				if (!await playCall(fake, options, fakeCall, `call-${index}-${call}`, client)) {
					if (script.noLastResult === true) {
						await aborted(options.abortController!.signal);
					}

					yield round.result ?? SUCCESS;

					return;
				}
			}

			if (index === 0 && script.hang === true) {
				await aborted(options.abortController!.signal);
			}

			if (index === 0 && script.throws !== undefined) {
				throw script.throws;
			}

			// The SDK reads the next prompt before the runner sends it.
			const nextPrompt = readPrompt();

			yield round.result ?? SUCCESS;

			if (!await nextPrompt) {
				return;
			}
		}
	} finally {
		await client.close();
	}
}

// Returns false when a hook ends the run.
async function playCall(fake: FakeQuery, options: Options, call: FakeCall, id: string, client: Client): Promise<boolean> {
	const tool = call.outside === true ? call.name : `mcp__${SERVER_NAME}__${call.name}`;
	const base = { session_id: "fake", transcript_path: "", cwd: options.cwd ?? "", tool_name: tool, tool_input: call.input ?? {}, tool_use_id: id };
	const before = await runHook(options, "PreToolUse", { ...base, hook_event_name: "PreToolUse" });

	if (before.continue === false) {
		return false;
	}

	const decision = before.hookSpecificOutput?.hookEventName === "PreToolUse" ? before.hookSpecificOutput.permissionDecision : undefined;

	if (decision !== "allow") {
		return true;
	}

	fake.called.push(call.name);

	const output = await callTool(client, call.name, call.input ?? {});
	const after = output.isError
		? await runHook(options, "PostToolUseFailure", { ...base, hook_event_name: "PostToolUseFailure", error: output.text })
		: await runHook(options, "PostToolUse", { ...base, hook_event_name: "PostToolUse", tool_response: output.text });

	return after.continue !== false;
}

async function runHook(options: Options, event: HookEvent, input: HookInput & { tool_use_id: string }): Promise<SyncHookJSONOutput> {
	const [matcher] = options.hooks?.[event] ?? [];

	// The runner's hooks all answer at once.
	return matcher === undefined ? {} : await matcher.hooks[0](input, input.tool_use_id, { signal: options.abortController!.signal }) as SyncHookJSONOutput;
}

// The SDK throws once its abort controller aborts.
function aborted(signal: AbortSignal): Promise<never> {
	return new Promise((_, reject) => {
		const fail = (): void => reject(new Error("Claude Code process aborted by user"));

		if (signal.aborted) {
			fail();
		}

		signal.addEventListener("abort", fail, { once: true });
	});
}
