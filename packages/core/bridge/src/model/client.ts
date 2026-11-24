// Calls a model through the Vercel AI SDK, so any provider works the same.
// The caller runs the tools. docs/design/core/model-client.md has the design.

import { APICallError, type JSONSchema7, type LanguageModel, type ModelMessage, RetryError, type ToolSet, jsonSchema, streamText, tool } from "ai";
import { type Effort, KEY_VARIABLES, type Provider } from "../config.js";

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

// The model, its provider for the messages, and the effort, where blank
// leaves the provider's default.
export interface ModelTarget {
	model: LanguageModel;
	provider: Provider;
	effort: Effort | "";
}

// A failure that the agent loop handles, instead of an exception. An auth
// failure stops the turn, because a retry would fail the same way.
export type ModelResult =
	| { ok: true; reply: ModelReply }
	| { ok: false; auth: boolean; error: string };

// Tools without an execute function, so the SDK returns their calls instead
// of running them.
function toToolSet(tools: ToolDefinition[]): ToolSet {
	return Object.fromEntries(tools.map(({ name, description, inputSchema }) => [
		name,
		tool({ description, inputSchema: jsonSchema(inputSchema) }),
	]));
}

// The SDK wraps the last error in a RetryError after a retry. An auth error
// names the key to check, and the rest give the last error's message. A
// provider may put something other than an error in the stream.
export function modelFailure(provider: Provider, error: unknown): ModelResult {
	const tries = RetryError.isInstance(error) ? error.errors.length : 1;
	const cause = RetryError.isInstance(error) ? error.lastError : error;
	const message = cause instanceof Error ? cause.message : String(cause);

	if (APICallError.isInstance(cause) && (cause.statusCode === 401 || cause.statusCode === 403)) {
		return {
			ok: false,
			auth: true,
			error: `${provider} refused the API key with ${cause.statusCode}: ${message}. Check providers.${provider}.apiKey in the config file, or ${KEY_VARIABLES[provider]}`,
		};
	}

	return { ok: false, auth: false, error: `The ${provider} model call failed${tries > 1 ? ` after ${tries} tries` : ""}: ${message}` };
}

// Streams the call, because a ChatGPT plan takes only streamed calls. The SDK
// retries only before the stream starts, and passes a later error to onError
// instead of throwing it.
export async function callModel({ model, provider, effort }: ModelTarget, request: ModelRequest): Promise<ModelResult> {
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
			return modelFailure(provider, streamError.error);
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
		return modelFailure(provider, error);
	}
}
