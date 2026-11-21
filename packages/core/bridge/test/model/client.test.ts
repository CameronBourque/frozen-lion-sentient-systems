// Tests for model/client.ts, with the AI SDK's mock model in place of a
// provider.

import { MockLanguageModelV4 } from "ai/test";
import { expect, test } from "vitest";
import { type ModelRequest, type ToolDefinition, callModel } from "../../src/model/client.js";

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

test("sends the system prompt, the messages, and the tools", async () => {
	const model = new MockLanguageModelV4({ doGenerate: reply([{ type: "text", text: "Done." }]) });

	await callModel(model, "", REQUEST);

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
	const model = new MockLanguageModelV4({ doGenerate: reply([{ type: "text", text: "Done." }]) });

	await callModel(model, "", REQUEST);

	expect(model.doGenerateCalls[0].reasoning).toBeUndefined();
});

test("sends the effort", async () => {
	const model = new MockLanguageModelV4({ doGenerate: reply([{ type: "text", text: "Done." }]) });

	await callModel(model, "high", REQUEST);

	expect(model.doGenerateCalls[0].reasoning).toBe("high");
});

test("returns the text and no tool calls when the model only writes", async () => {
	const model = new MockLanguageModelV4({ doGenerate: reply([{ type: "text", text: "I'll wait." }]) });

	expect(await callModel(model, "", REQUEST)).toEqual({ text: "I'll wait.", toolCalls: [], usage: { inputTokens: 10, outputTokens: 5 } });
});

test("returns the tool calls without running them", async () => {
	const model = new MockLanguageModelV4({
		doGenerate: reply([
			{ type: "text", text: "Ending the turn." },
			{ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: "{\"reason\":\"Nothing left.\"}" },
		]),
	});

	expect(await callModel(model, "", REQUEST)).toEqual({
		text: "Ending the turn.",
		toolCalls: [{ id: "call-1", name: "end_turn", input: { reason: "Nothing left." } }],
		usage: { inputTokens: 10, outputTokens: 5 },
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

	expect((await callModel(model, "", REQUEST)).usage).toEqual({ inputTokens: 0, outputTokens: 0 });
});
