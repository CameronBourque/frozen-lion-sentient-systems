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

// hang waits for the abort after the calls, as a model that never answers.
// result is the message the run ends with, or a throw in its place.
export interface FakeScript {
	calls: FakeCall[];
	hang?: true;
	result?: SDKMessage;
	throws?: Error;
}

export interface FakeQuery {
	query: QueryFunction;
	params: { prompt: string; options: Options }[];
	// The tools the run called, by the bridge's name.
	called: string[];
}

const SUCCESS = { type: "result", subtype: "success" } as SDKMessage;

export function fakeQuery(script: FakeScript): FakeQuery {
	const fake: FakeQuery = { query: (params) => play(fake, script, params), params: [], called: [] };

	return fake;
}

async function* play(fake: FakeQuery, script: FakeScript, params: { prompt: string; options: Options }): AsyncGenerator<SDKMessage> {
	fake.params.push(params);

	const { options } = params;
	const { url } = options.mcpServers?.[SERVER_NAME] as { url: string };
	const client = new Client({ name: "fake-sdk", version: "1.0.0" });

	await client.connect(new StreamableHTTPClientTransport(new URL(url)));

	try {
		for (const [index, call] of script.calls.entries()) {
			// A hook that ends the run still gets the SDK's result.
			if (!await playCall(fake, options, call, `call-${index}`, client)) {
				yield SUCCESS;

				return;
			}
		}

		if (script.hang === true) {
			await aborted(options.abortController!.signal);
		}

		if (script.throws !== undefined) {
			throw script.throws;
		}

		yield script.result ?? SUCCESS;
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
