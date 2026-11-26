// Tests for model/client.ts, with the AI SDK's mock model in place of a
// provider, and fake timers for the retries.

import { APICallError } from "ai";
import { MockLanguageModelV4 } from "ai/test";
import { afterEach, describe, expect, test, vi } from "vitest";
import type { Effort, Provider } from "../../src/config.js";
import type { RunMode } from "../../src/model/providers/provider.js";
import { USAGE, done, partsOf, reply, replying, stream } from "./mock-model.js";
import { MAX_RETRIES, type ModelRequest, type ModelTarget, type ToolDefinition, callModel, isCallMode, modelFailure } from "../../src/model/client.js";

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
	return { model, provider, mode: "api-key", effort };
}

// An API error as a provider's package throws it.
function apiError(statusCode: number, message: string, responseBody?: string): APICallError {
	return new APICallError({ message, url: "https://api.example.com", requestBodyValues: {}, statusCode, responseBody });
}

// A ChatGPT plan's error, with its code in the body as OpenAI sends it.
function subscriptionError(statusCode: number, code: string): APICallError {
	return apiError(statusCode, "Plan error", JSON.stringify({ error: { code, message: "Plan error" } }));
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
		reply: {
			text: "I'll wait.",
			toolCalls: [],
			messages: [{ role: "assistant", content: [{ type: "text", text: "I'll wait." }] }],
			usage: { inputTokens: 10, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 5 },
		},
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
			messages: [{
				role: "assistant",
				content: [
					{ type: "text", text: "Ending the turn." },
					{ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: { reason: "Nothing left." } },
				],
			}],
			usage: { inputTokens: 10, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 5 },
		},
	});
	expect(model.doStreamCalls).toHaveLength(1);
});

test("the reply's messages keep the model's reasoning, so the next call sends it back", async () => {
	const model = replying(() => stream([
		{ type: "stream-start", warnings: [] },
		{ type: "reasoning-start", id: "reasoning-1" },
		{ type: "reasoning-delta", id: "reasoning-1", delta: "No moves left." },
		{ type: "reasoning-end", id: "reasoning-1" },
		...partsOf({ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: "{\"reason\":\"Done.\"}" }),
		{ type: "finish", finishReason: { unified: "tool-calls", raw: undefined }, usage: USAGE },
	]));

	expect(await callModel(target(model), REQUEST)).toMatchObject({
		reply: { messages: [{ role: "assistant", content: [{ type: "reasoning", text: "No moves left." }, { type: "tool-call", toolCallId: "call-1" }] }] },
	});
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
			kind: "other",
			error: `The anthropic model call failed after ${MAX_RETRIES + 1} tries: Internal error`,
		});
		expect(model.doStreamCalls).toHaveLength(MAX_RETRIES + 1);
	});

	test("doesn't retry a refused key, and names the key to check", async () => {
		const model = failingModel([apiError(401, "invalid x-api-key")]);

		expect(await callModel(target(model), REQUEST)).toEqual({
			ok: false,
			kind: "auth",
			error: "anthropic refused the API key with 401: invalid x-api-key. Check providers.anthropic.apiKey in the config file, or ANTHROPIC_API_KEY",
		});
		expect(model.doStreamCalls).toHaveLength(1);
	});

	test("finds a refused key after a retry", async () => {
		vi.useFakeTimers();

		const model = failingModel([apiError(503, "Unavailable"), apiError(403, "Forbidden")]);
		const result = callModel(target(model, "", "google"), REQUEST);

		await vi.advanceTimersByTimeAsync(2000);

		expect(await result).toMatchObject({ ok: false, kind: "auth", error: expect.stringMatching(/^google refused the API key with 403: Forbidden\. Check providers\.google\.apiKey/) as unknown });
	});

	test("doesn't retry an error after the stream starts, and gives its message", async () => {
		const model = replying(() => stream([
			{ type: "stream-start", warnings: [] },
			...partsOf({ type: "text", text: "Ending" }),
			{ type: "error", error: apiError(429, "Usage limit reached") },
		]));

		expect(await callModel(target(model, "", "openai"), REQUEST)).toEqual({
			ok: false,
			kind: "other",
			error: "The openai model call failed: Usage limit reached",
		});
		expect(model.doStreamCalls).toHaveLength(1);
	});

	test("fails when the stream ends with no reply", async () => {
		const model = replying(() => stream([{ type: "stream-start", warnings: [] }]));

		expect(await callModel(target(model), REQUEST)).toMatchObject({ ok: false, kind: "other" });
	});
});

describe("modelFailure", () => {
	test("passes on any other error's message", () => {
		expect(modelFailure("openai", "api-key", new Error("fetch failed"))).toEqual({ ok: false, kind: "other", error: "The openai model call failed: fetch failed" });
	});

	test("names an error that isn't an Error", () => {
		expect(modelFailure("openai", "api-key", "socket closed")).toEqual({ ok: false, kind: "other", error: "The openai model call failed: socket closed" });
	});

	test("treats an API error without a refused key as a failure", () => {
		expect(modelFailure("openai", "api-key", apiError(400, "Bad request"))).toEqual({ ok: false, kind: "other", error: "The openai model call failed: Bad request" });
	});

	test("tells a plan user to sign in again when the plan refuses the token", () => {
		expect(modelFailure("openai", "subscription", apiError(401, "Expired"))).toEqual({
			ok: false,
			kind: "auth",
			error: "openai refused the plan sign-in with 401: Expired. Sign in again from the Run mode menu",
		});
	});

	test.each([
		[429, "subscription_sharing_usage_limit_exceeded", "limit", "The ChatGPT plan's usage limit is reached: Plan error. https://chatgpt.com/settings/usage shows when it resets"],
		[403, "subscription_sharing_user_not_eligible", "not-eligible", "This ChatGPT account's plan can't be used by other apps: Plan error"],
		[503, "subscription_sharing_usage_unavailable", "unavailable", "ChatGPT plan usage is unavailable right now: Plan error"],
		[400, "subscription_sharing_unsupported_capability", "unsupported", "The ChatGPT plan rejected a field the bridge sent, which is a bridge bug. Report it with this message: Plan error"],
	])("marks a %i with %s as its own kind", (status, code, kind, error) => {
		expect(modelFailure("openai", "subscription", subscriptionError(status, code))).toEqual({ ok: false, kind, error });
	});
});

test("marks a plan's usage limit that arrives mid-stream", async () => {
	// The OpenAI package gives a failed response a status from its code,
	// which is 500 for this one.
	const failed = apiError(500, "Usage limit reached", JSON.stringify({ type: "response.failed", response: { error: { code: "subscription_sharing_usage_limit_exceeded", message: "Usage limit reached" } } }));
	const model = replying(() => stream([
		{ type: "stream-start", warnings: [] },
		...partsOf({ type: "text", text: "Ending" }),
		{ type: "error", error: failed },
	]));

	expect(await callModel({ ...target(model, "", "openai"), mode: "subscription" }, REQUEST)).toMatchObject({ ok: false, kind: "limit" });
	expect(model.doStreamCalls).toHaveLength(1);
});

test("calls the model only in the modes that use the bridge's loop", () => {
	expect(["api-key", "subscription", "agent-sdk", "cli"].filter((mode) => isCallMode(mode as RunMode))).toEqual(["api-key", "subscription"]);
});
