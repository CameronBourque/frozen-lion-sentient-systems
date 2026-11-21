// Tests for model/client.ts, with the AI SDK's mock model in place of a
// provider, and fake timers for the retries.

import { APICallError } from "ai";
import { MockLanguageModelV4 } from "ai/test";
import { afterEach, describe, expect, test, vi } from "vitest";
import type { Effort, Provider } from "../../src/config.js";
import { MAX_RETRIES, type ModelRequest, type ModelTarget, type ToolDefinition, callModel, modelFailure } from "../../src/model/client.js";

// @ai-sdk/provider names this type, but the bridge doesn't depend on it.
type GenerateResult = Awaited<ReturnType<MockLanguageModelV4["doGenerate"]>>;

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

function target(model: MockLanguageModelV4, effort: Effort | "" = "", provider: Provider = "anthropic"): ModelTarget {
	return { model, provider, effort };
}

function reply(content: GenerateResult["content"]): GenerateResult {
	return {
		content,
		finishReason: { unified: "stop", raw: undefined },
		usage: {
			inputTokens: { total: 10, noCache: 10, cacheRead: undefined, cacheWrite: undefined },
			outputTokens: { total: 5, text: 5, reasoning: undefined },
		},
		warnings: [],
	};
}

const DONE = reply([{ type: "text", text: "Done." }]);

// An API error as a provider's package throws it.
function apiError(statusCode: number, message: string): APICallError {
	return new APICallError({ message, url: "https://api.example.com", requestBodyValues: {}, statusCode });
}

// A model that fails with each error in turn, then answers.
function failingModel(errors: Error[]): MockLanguageModelV4 {
	return new MockLanguageModelV4({
		doGenerate: () => {
			const error = errors.shift();

			return error === undefined ? Promise.resolve(DONE) : Promise.reject(error);
		},
	});
}

test("sends the system prompt, the messages, and the tools", async () => {
	const model = new MockLanguageModelV4({ doGenerate: DONE });

	await callModel(target(model), REQUEST);

	const [call] = model.doGenerateCalls;

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
	const model = new MockLanguageModelV4({ doGenerate: DONE });

	await callModel(target(model), REQUEST);

	expect(model.doGenerateCalls[0].reasoning).toBeUndefined();
});

test("sends the effort", async () => {
	const model = new MockLanguageModelV4({ doGenerate: DONE });

	await callModel(target(model, "high"), REQUEST);

	expect(model.doGenerateCalls[0].reasoning).toBe("high");
});

test("returns the text and no tool calls when the model only writes", async () => {
	const model = new MockLanguageModelV4({ doGenerate: reply([{ type: "text", text: "I'll wait." }]) });

	expect(await callModel(target(model), REQUEST)).toEqual({
		ok: true,
		reply: { text: "I'll wait.", toolCalls: [], usage: { inputTokens: 10, outputTokens: 5 } },
	});
});

test("returns the tool calls without running them", async () => {
	const model = new MockLanguageModelV4({
		doGenerate: reply([
			{ type: "text", text: "Ending the turn." },
			{ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: "{\"reason\":\"Nothing left.\"}" },
		]),
	});

	expect(await callModel(target(model), REQUEST)).toEqual({
		ok: true,
		reply: {
			text: "Ending the turn.",
			toolCalls: [{ id: "call-1", name: "end_turn", input: { reason: "Nothing left." } }],
			usage: { inputTokens: 10, outputTokens: 5 },
		},
	});
	expect(model.doGenerateCalls).toHaveLength(1);
});

test("counts tokens the provider doesn't report as 0", async () => {
	const unreported = reply([{ type: "text", text: "Done." }]);

	unreported.usage = {
		inputTokens: { total: undefined, noCache: undefined, cacheRead: undefined, cacheWrite: undefined },
		outputTokens: { total: undefined, text: undefined, reasoning: undefined },
	};

	const model = new MockLanguageModelV4({ doGenerate: unreported });

	expect(await callModel(target(model), REQUEST)).toMatchObject({ reply: { usage: { inputTokens: 0, outputTokens: 0 } } });
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
		expect(model.doGenerateCalls).toHaveLength(3);
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
		expect(model.doGenerateCalls).toHaveLength(MAX_RETRIES + 1);
	});

	test("doesn't retry a refused key, and names the key to check", async () => {
		const model = failingModel([apiError(401, "invalid x-api-key")]);

		expect(await callModel(target(model), REQUEST)).toEqual({
			ok: false,
			auth: true,
			error: "anthropic refused the API key with 401: invalid x-api-key. Check providers.anthropic.apiKey in the config file, or ANTHROPIC_API_KEY",
		});
		expect(model.doGenerateCalls).toHaveLength(1);
	});

	test("finds a refused key after a retry", async () => {
		vi.useFakeTimers();

		const model = failingModel([apiError(503, "Unavailable"), apiError(403, "Forbidden")]);
		const result = callModel(target(model, "", "google"), REQUEST);

		await vi.advanceTimersByTimeAsync(2000);

		expect(await result).toMatchObject({ ok: false, auth: true, error: expect.stringMatching(/^google refused the API key with 403: Forbidden\. Check providers\.google\.apiKey/) as unknown });
	});
});

describe("modelFailure", () => {
	test("passes on any other error's message", () => {
		expect(modelFailure("openai", new Error("fetch failed"))).toEqual({ ok: false, auth: false, error: "The openai model call failed: fetch failed" });
	});

	test("treats an API error without a refused key as a failure", () => {
		expect(modelFailure("openai", apiError(400, "Bad request"))).toEqual({ ok: false, auth: false, error: "The openai model call failed: Bad request" });
	});
});
