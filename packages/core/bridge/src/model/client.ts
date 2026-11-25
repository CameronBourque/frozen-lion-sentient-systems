// Calls a model through the Vercel AI SDK, so any provider works the same.
// The caller runs the tools. docs/design/core/model-client.md has the design.

import { APICallError, type JSONSchema7, type LanguageModel, type ModelMessage, RetryError, type ToolSet, jsonSchema, streamText, tool } from "ai";
import { type Effort, KEY_VARIABLES, type Provider } from "../config.js";
import type { RunMode } from "./providers/provider.js";

// Retries after a rate limit or a server error, with backoff from 2 seconds.
export const MAX_RETRIES = 3;

// A tool the model may call. The input schema is JSON Schema, which the MCP
// tools already have.
export interface ToolDefinition {
	name: string;
	description: string;
	inputSchema: JSONSchema7;
}

export interface ModelRequest {
	system: string;
	messages: ModelMessage[];
	tools: ToolDefinition[];
}

export interface ToolCall {
	id: string;
	name: string;
	input: unknown;
}

// inputTokens counts every input token, cached or not.
export interface Usage {
	inputTokens: number;
	cacheReadTokens: number;
	cacheWriteTokens: number;
	outputTokens: number;
}

export interface ModelReply {
	text: string;
	toolCalls: ToolCall[];
	usage: Usage;
}

// What a refused credential is called in each run mode that calls through
// the client, and how the user fixes it.
const AUTH_FIXES = {
	"api-key": {
		credential: "the API key",
		fix: (provider: Provider) => `Check providers.${provider}.apiKey in the config file, or ${KEY_VARIABLES[provider]}`,
	},
	subscription: {
		credential: "the plan sign-in",
		fix: () => "Sign in again from the Run mode menu",
	},
} satisfies Partial<Record<RunMode, { credential: string; fix: (provider: Provider) => string }>>;

export type CallMode = keyof typeof AUTH_FIXES;

// The run modes the model client calls in, as opposed to an agent SDK or a
// CLI, which run their own loop.
export function isCallMode(mode: RunMode): mode is CallMode {
	return mode in AUTH_FIXES;
}

// The model, its provider for the messages, the run mode for the auth
// message, and the effort, where blank leaves the provider's default.
export interface ModelTarget {
	model: LanguageModel;
	provider: Provider;
	mode: CallMode;
	effort: Effort | "";
}

export const SUBSCRIPTION_USAGE_URL = "https://chatgpt.com/settings/usage";

interface Failed {
	provider: Provider;
	mode: CallMode;
	cause: unknown;
	message: string;
}

// A plan's error code, in a refused request's body or in a stream error's
// frame, which the OpenAI package also puts in responseBody.
export function hasCode(code: string): (cause: unknown) => cause is APICallError {
	return (cause): cause is APICallError => APICallError.isInstance(cause) && (cause.responseBody ?? "").includes(code);
}

export const USAGE_LIMIT_CODE = "subscription_sharing_usage_limit_exceeded";

function refused(cause: unknown): boolean {
	return APICallError.isInstance(cause) && (cause.statusCode === 401 || cause.statusCode === 403);
}

// Every failure the bridge knows, first match first. The plan's codes come
// before auth, because a plan account that isn't eligible gets a 403.
const FAILURES = [
	{
		kind: "limit",
		matches: hasCode(USAGE_LIMIT_CODE),
		message: ({ message }: Failed) => `The ChatGPT plan's usage limit is reached: ${message}. ${SUBSCRIPTION_USAGE_URL} shows when it resets`,
	},
	{
		kind: "not-eligible",
		matches: hasCode("subscription_sharing_user_not_eligible"),
		message: ({ message }: Failed) => `This ChatGPT account's plan can't be used by other apps: ${message}`,
	},
	{
		kind: "unavailable",
		matches: hasCode("subscription_sharing_usage_unavailable"),
		message: ({ message }: Failed) => `ChatGPT plan usage is unavailable right now: ${message}`,
	},
	{
		kind: "unsupported",
		matches: hasCode("subscription_sharing_unsupported_capability"),
		message: ({ message }: Failed) => `The ChatGPT plan rejected a field the bridge sent, which is a bridge bug. Report it with this message: ${message}`,
	},
	{
		kind: "auth",
		matches: refused,
		message: ({ provider, mode, cause, message }: Failed) => `${provider} refused ${AUTH_FIXES[mode].credential} with ${(cause as APICallError).statusCode}: ${message}. ${AUTH_FIXES[mode].fix(provider)}`,
	},
] as const;

export type FailureKind = typeof FAILURES[number]["kind"] | "other";

// A failure that the agent loop handles, instead of an exception. Its kind
// says what the loop does next. An auth failure stops the turn, because a
// retry would fail the same way.
export type ModelResult =
	| { ok: true; reply: ModelReply }
	| { ok: false; kind: FailureKind; error: string };

// Tools without an execute function, so the SDK returns their calls instead
// of running them.
function toToolSet(tools: ToolDefinition[]): ToolSet {
	return Object.fromEntries(tools.map(({ name, description, inputSchema }) => [
		name,
		tool({ description, inputSchema: jsonSchema(inputSchema) }),
	]));
}

// The SDK wraps the last error in a RetryError after a retry. A known failure
// gets its own message, and the rest give the last error's message. A
// provider may put something other than an error in the stream.
export function modelFailure(provider: Provider, mode: CallMode, error: unknown): ModelResult {
	const tries = RetryError.isInstance(error) ? error.errors.length : 1;
	const cause = RetryError.isInstance(error) ? error.lastError : error;
	const message = cause instanceof Error ? cause.message : String(cause);
	const known = FAILURES.find(({ matches }) => matches(cause));

	if (known !== undefined) {
		return { ok: false, kind: known.kind, error: known.message({ provider, mode, cause, message }) };
	}

	return { ok: false, kind: "other", error: `The ${provider} model call failed${tries > 1 ? ` after ${tries} tries` : ""}: ${message}` };
}

// Streams the call, because a ChatGPT plan takes only streamed calls. The SDK
// retries only before the stream starts, and passes a later error to onError
// instead of throwing it.
export async function callModel({ model, provider, mode, effort }: ModelTarget, request: ModelRequest): Promise<ModelResult> {
	let streamError: { error: unknown } | undefined;

	try {
		const result = streamText({
			model,
			reasoning: effort === "" ? undefined : effort,
			instructions: request.system,
			messages: request.messages,
			tools: toToolSet(request.tools),
			maxRetries: MAX_RETRIES,
			onError: ({ error }) => {
				streamError ??= { error };
			},
		});

		await result.consumeStream();

		if (streamError !== undefined) {
			return modelFailure(provider, mode, streamError.error);
		}

		const [text, toolCalls, usage] = await Promise.all([result.text, result.toolCalls, result.usage]);

		return {
			ok: true,
			reply: {
				text,
				toolCalls: toolCalls.map(({ toolCallId, toolName, input }): ToolCall => ({ id: toolCallId, name: toolName, input })),
				// A provider that doesn't report a count counts as 0, so a sum
				// still adds up.
				usage: {
					inputTokens: usage.inputTokens ?? 0,
					cacheReadTokens: usage.inputTokenDetails.cacheReadTokens ?? 0,
					cacheWriteTokens: usage.inputTokenDetails.cacheWriteTokens ?? 0,
					outputTokens: usage.outputTokens ?? 0,
				},
			},
		};
	} catch (error) {
		// The reply's promises reject with no onError call when the call is
		// aborted, which the stop key will do.
		return modelFailure(provider, mode, error);
	}
}
