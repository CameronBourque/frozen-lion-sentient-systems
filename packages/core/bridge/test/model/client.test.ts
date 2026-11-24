// Tests for model/client.ts, with the AI SDK's mock model in place of a
// provider, and fake timers for the retries.

import { APICallError, simulateReadableStream } from "ai";
import { MockLanguageModelV4 } from "ai/test";
import { afterEach, describe, expect, test, vi } from "vitest";
import type { Effort, Provider } from "../../src/config.js";
import { MAX_RETRIES, type ModelRequest, type ModelTarget, type ToolDefinition, callModel, modelFailure } from "../../src/model/client.js";

// @ai-sdk/provider names these types, but the bridge doesn't depend on it.
type StreamResult = Awaited<ReturnType<MockLanguageModelV4["doStream"]>>;
type StreamPart = StreamResult["stream"] extends ReadableStream<infer Part> ? Part : never;
type Usage = Extract<StreamPart, { type: "finish" }>["usage"];

// What the model writes and calls, before the test turns it into stream parts.
type Content =
	| { type: "text"; text: string }
	| { type: "tool-call"; toolCallId: string; toolName: string; input: string };

const END_TURN: ToolDefinition = {
	name: "end_turn",
	description: "Ends the turn.",
	inputSchema: {
		type: "object",
		properties: { reason: { type: "string" } },
		required: ["reason"],
	},
};

const REQUEST: ModelRequest = {
	system: "You play Civilization VI.",
	messages: [{ role: "user", content: "Your turn." }],
	tools: [END_TURN],
};

const USAGE: Usage = {
	inputTokens: { total: 10, noCache: 10, cacheRead: undefined, cacheWrite: undefined },
	outputTokens: { total: 5, text: 5, reasoning: undefined },
};

function target(model: MockLanguageModelV4, effort: Effort | "" = "", provider: Provider = "anthropic"): ModelTarget {
	return { model, provider, effort };
}

// Each text arrives in two deltas, so the test checks that the client joins
// them.
function partsOf(content: Content): StreamPart[] {
	if (content.type === "tool-call") {
		return [content];
	}

	const half = Math.ceil(content.text.length / 2);

	return [
		{ type: "text-start", id: "text-1" },
		{ type: "text-delta", id: "text-1", delta: content.text.slice(0, half) },
		{ type: "text-delta", id: "text-1", delta: content.text.slice(half) },
		{ type: "text-end", id: "text-1" },
	];
}

function stream(parts: StreamPart[]): StreamResult {
	return { stream: simulateReadableStream({ chunks: parts, initialDelayInMs: null, chunkDelayInMs: null }) };
}

function reply(content: Content[], usage: Usage = USAGE): StreamResult {
	return stream([
		{ type: "stream-start", warnings: [] },
		...content.flatMap(partsOf),
		{ type: "finish", finishReason: { unified: "stop", raw: undefined }, usage },
	]);
}

function done(): StreamResult {
	return reply([{ type: "text", text: "Done." }]);
}

function replying(make: () => StreamResult): MockLanguageModelV4 {
	return new MockLanguageModelV4({ doStream: () => Promise.resolve(make()) });
}

// An API error as a provider's package throws it.
function apiError(statusCode: number, message: string): APICallError {
	return new APICallError({ message, url: "https://api.example.com", requestBodyValues: {}, statusCode });
}

// A model that fails to start the stream with each error in turn, then
// answers.
function failingModel(errors: Error[]): MockLanguageModelV4 {
	return new MockLanguageModelV4({
		doStream: () => {
			const error = errors.shift();

			return error === undefined ? Promise.resolve(done()) : Promise.reject(error);
		},
	});
}

test("sends the system prompt, the messages, and the tools", async () => {
	const model = replying(done);

	await callModel(target(model), REQUEST);

	const [call] = model.doStreamCalls;

	expect(call.prompt).toEqual([
		{ role: "system", content: "You play Civilization VI." },
		{ role: "user", content: [{ type: "text", text: "Your turn." }] },
	]);
	expect(call.tools).toEqual([expect.objectContaining({
		type: "function",
		name: "end_turn",
		description: "Ends the turn.",
		inputSchema: END_TURN.inputSchema,
	})]);
});

test("leaves the provider's effort when the effort is blank", async () => {
	const model = replying(done);

	await callModel(target(model), REQUEST);

	expect(model.doStreamCalls[0].reasoning).toBeUndefined();
});

test("sends the effort", async () => {
	const model = replying(done);

	await callModel(target(model, "high"), REQUEST);

	expect(model.doStreamCalls[0].reasoning).toBe("high");
});

test("returns the text and no tool calls when the model only writes", async () => {
	const model = replying(() => reply([{ type: "text", text: "I'll wait." }]));

	expect(await callModel(target(model), REQUEST)).toEqual({
		ok: true,
		reply: { text: "I'll wait.", toolCalls: [], usage: { inputTokens: 10, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 5 } },
	});
});

test("returns the tool calls without running them", async () => {
	const model = replying(() => reply([
		{ type: "text", text: "Ending the turn." },
		{ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: "{\"reason\":\"Nothing left.\"}" },
	]));

	expect(await callModel(target(model), REQUEST)).toEqual({
		ok: true,
		reply: {
			text: "Ending the turn.",
			toolCalls: [{ id: "call-1", name: "end_turn", input: { reason: "Nothing left." } }],
			usage: { inputTokens: 10, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 5 },
		},
	});
	expect(model.doStreamCalls).toHaveLength(1);
});

test("counts tokens the provider doesn't report as 0", async () => {
	const model = replying(() => reply([{ type: "text", text: "Done." }], {
		inputTokens: { total: undefined, noCache: undefined, cacheRead: undefined, cacheWrite: undefined },
		outputTokens: { total: undefined, text: undefined, reasoning: undefined },
	}));

	expect(await callModel(target(model), REQUEST)).toMatchObject({ reply: { usage: { inputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 0 } } });
});

test("returns the tokens read from and written to the prompt cache", async () => {
	const model = replying(() => reply([{ type: "text", text: "Done." }], {
		inputTokens: { total: 100, noCache: 20, cacheRead: 70, cacheWrite: 10 },
		outputTokens: { total: 5, text: 5, reasoning: undefined },
	}));

	expect(await callModel(target(model), REQUEST)).toMatchObject({
		reply: { usage: { inputTokens: 100, cacheReadTokens: 70, cacheWriteTokens: 10, outputTokens: 5 } },
	});
});

describe("failures", () => {
	afterEach(() => {
		vi.useRealTimers();
	});

	test("retries a rate limit and a server error with backoff, then answers", async () => {
		vi.useFakeTimers();

		const model = failingModel([apiError(429, "Too many requests"), apiError(529, "Overloaded")]);
		const result = callModel(target(model), REQUEST);

		// 2 seconds, then 4.
		await vi.advanceTimersByTimeAsync(6000);

		expect(await result).toMatchObject({ ok: true });
		expect(model.doStreamCalls).toHaveLength(3);
	});

	test("gives up after the last retry", async () => {
		vi.useFakeTimers();

		const model = failingModel(Array.from({ length: MAX_RETRIES + 1 }, () => apiError(500, "Internal error")));
		const result = callModel(target(model), REQUEST);

		// 2, 4, and 8 seconds.
		await vi.advanceTimersByTimeAsync(14000);

		expect(await result).toEqual({
			ok: false,
			auth: false,
			error: `The anthropic model call failed after ${MAX_RETRIES + 1} tries: Internal error`,
		});
		expect(model.doStreamCalls).toHaveLength(MAX_RETRIES + 1);
	});

	test("doesn't retry a refused key, and names the key to check", async () => {
		const model = failingModel([apiError(401, "invalid x-api-key")]);

		expect(await callModel(target(model), REQUEST)).toEqual({
			ok: false,
			auth: true,
			error: "anthropic refused the API key with 401: invalid x-api-key. Check providers.anthropic.apiKey in the config file, or ANTHROPIC_API_KEY",
		});
		expect(model.doStreamCalls).toHaveLength(1);
	});

	test("finds a refused key after a retry", async () => {
		vi.useFakeTimers();

		const model = failingModel([apiError(503, "Unavailable"), apiError(403, "Forbidden")]);
		const result = callModel(target(model, "", "google"), REQUEST);

		await vi.advanceTimersByTimeAsync(2000);

		expect(await result).toMatchObject({ ok: false, auth: true, error: expect.stringMatching(/^google refused the API key with 403: Forbidden\. Check providers\.google\.apiKey/) as unknown });
	});

	test("doesn't retry an error after the stream starts, and gives its message", async () => {
		const model = replying(() => stream([
			{ type: "stream-start", warnings: [] },
			...partsOf({ type: "text", text: "Ending" }),
			{ type: "error", error: apiError(429, "Usage limit reached") },
		]));

		expect(await callModel(target(model, "", "openai"), REQUEST)).toEqual({
			ok: false,
			auth: false,
			error: "The openai model call failed: Usage limit reached",
		});
		expect(model.doStreamCalls).toHaveLength(1);
	});

	test("fails when the stream ends with no reply", async () => {
		const model = replying(() => stream([{ type: "stream-start", warnings: [] }]));

		expect(await callModel(target(model), REQUEST)).toMatchObject({ ok: false, auth: false });
	});
});

describe("modelFailure", () => {
	test("passes on any other error's message", () => {
		expect(modelFailure("openai", new Error("fetch failed"))).toEqual({ ok: false, auth: false, error: "The openai model call failed: fetch failed" });
	});

	test("names an error that isn't an Error", () => {
		expect(modelFailure("openai", "socket closed")).toEqual({ ok: false, auth: false, error: "The openai model call failed: socket closed" });
	});

	test("treats an API error without a refused key as a failure", () => {
		expect(modelFailure("openai", apiError(400, "Bad request"))).toEqual({ ok: false, auth: false, error: "The openai model call failed: Bad request" });
	});
});
