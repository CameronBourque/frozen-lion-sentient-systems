// Calls a model through the Vercel AI SDK, so any provider works the same.
// The caller runs the tools. docs/design/core/model-client.md has the design.

import { type JSONSchema7, type LanguageModel, type ModelMessage, type ToolSet, generateText, jsonSchema, tool } from "ai";
import type { Effort } from "../config.js";

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

export interface Usage {
	inputTokens: number;
	outputTokens: number;
}

export interface ModelReply {
	text: string;
	toolCalls: ToolCall[];
	usage: Usage;
}

// Tools without an execute function, so the SDK returns their calls instead
// of running them.
function toToolSet(tools: ToolDefinition[]): ToolSet {
	return Object.fromEntries(tools.map(({ name, description, inputSchema }) => [
		name,
		tool({ description, inputSchema: jsonSchema(inputSchema) }),
	]));
}

// A blank effort leaves the provider's default.
export async function callModel(model: LanguageModel, effort: Effort | "", request: ModelRequest): Promise<ModelReply> {
	const result = await generateText({
		model,
		reasoning: effort === "" ? undefined : effort,
		instructions: request.system,
		messages: request.messages,
		tools: toToolSet(request.tools),
	});

	return {
		text: result.text,
		toolCalls: result.toolCalls.map(({ toolCallId, toolName, input }): ToolCall => ({ id: toolCallId, name: toolName, input })),
		// A provider that doesn't report a count counts as 0, so a sum still
		// adds up.
		usage: { inputTokens: result.usage.inputTokens ?? 0, outputTokens: result.usage.outputTokens ?? 0 },
	};
}
