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

	await callModel(model, REQUEST);

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

test("returns the text and no tool calls when the model only writes", async () => {
	const model = new MockLanguageModelV4({ doGenerate: reply([{ type: "text", text: "I'll wait." }]) });

	expect(await callModel(model, REQUEST)).toEqual({ text: "I'll wait.", toolCalls: [] });
});

test("returns the tool calls without running them", async () => {
	const model = new MockLanguageModelV4({
		doGenerate: reply([
			{ type: "text", text: "Ending the turn." },
			{ type: "tool-call", toolCallId: "call-1", toolName: "end_turn", input: "{\"reason\":\"Nothing left.\"}" },
		]),
	});

	expect(await callModel(model, REQUEST)).toEqual({
		text: "Ending the turn.",
		toolCalls: [{ id: "call-1", name: "end_turn", input: { reason: "Nothing left." } }],
	});
	expect(model.doGenerateCalls).toHaveLength(1);
});
