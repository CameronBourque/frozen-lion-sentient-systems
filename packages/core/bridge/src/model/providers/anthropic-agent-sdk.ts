// Anthropic's Agent SDK run mode: the SDK lists the models, and the Agent SDK
// runner plays the turns. docs/design/core/anthropic-agent-sdk-runner.md has
// the design.

import { type ModelInfo as SdkModel, type Options, type SDKUserMessage, query as sdkQuery } from "@anthropic-ai/claude-agent-sdk";
import { type QueryFunction, anthropicAgentSdkRunner } from "../../agents/runners/anthropic-agent-sdk-runner.js";
import type { Effort } from "../../config.js";
import type { ListResult, ModelInfo } from "../list-models.js";
import type { ModeSupport } from "./provider.js";

// A session that only reports what the SDK has, such as its models.
export interface InfoSession {
	supportedModels: () => Promise<SdkModel[]>;
	close: () => void;
}

// The SDK's query(), or fakes in tests: one that plays turns, and one that
// opens a session only to read from it.
export interface AgentSdk {
	query: QueryFunction;
	info: (params: { prompt: AsyncIterable<SDKUserMessage>; options: Options }) => InfoSession;
}

const SDK: AgentSdk = { query: sdkQuery, info: sdkQuery };

// The session loads no tools, settings, or files, and makes no model call.
const INFO_OPTIONS: Options = { tools: [], settingSources: [], strictMcpConfig: true, persistSession: false };

export function agentSdkMode(sdk: AgentSdk = SDK): ModeSupport {
	return {
		ready: () => ({ ok: true }),
		listModels: () => listModels(sdk),
		runner: (config) => ({ ok: true, runner: anthropicAgentSdkRunner(config.model, sdk.query) }),
	};
}

// The SDK names its models by alias, such as opus, which OpenRouter doesn't
// list, so each model brings its own efforts.
async function listModels(sdk: AgentSdk): Promise<ListResult> {
	const done = new AbortController();
	const session = sdk.info({ prompt: idle(done.signal), options: INFO_OPTIONS });

	try {
		return { ok: true, models: (await session.supportedModels()).map(modelInfo) };
	} catch (error) {
		return { ok: false, error: `The Agent SDK couldn't list its models: ${String(error)}` };
	} finally {
		done.abort();
		session.close();
	}
}

function modelInfo({ value, displayName, supportedEffortLevels }: SdkModel): ModelInfo {
	const efforts: Effort[] = ["provider-default", ...(supportedEffortLevels ?? [])];

	return { id: value, name: displayName, efforts };
}

// A prompt that sends nothing, so the session waits until it closes.
function idle(signal: AbortSignal): AsyncIterable<SDKUserMessage> {
	const end = new Promise<IteratorResult<SDKUserMessage>>((resolve) => signal.addEventListener("abort", () => resolve({ done: true, value: undefined }), { once: true }));

	return { [Symbol.asyncIterator]: () => ({ next: () => end }) };
}
