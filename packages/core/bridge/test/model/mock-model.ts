// Test helpers for the AI SDK's mock model: replies built from what the model
// writes and calls, turned into the stream parts a provider sends.

import { simulateReadableStream } from "ai";
import { MockLanguageModelV4 } from "ai/test";

// @ai-sdk/provider names these types, but the bridge doesn't depend on it.
export type StreamResult = Awaited<ReturnType<MockLanguageModelV4["doStream"]>>;
export type StreamPart = StreamResult["stream"] extends ReadableStream<infer Part> ? Part : never;
export type Usage = Extract<StreamPart, { type: "finish" }>["usage"];

// What the model writes and calls, before it becomes stream parts.
export type Content =
	| { type: "text"; text: string }
	| { type: "tool-call"; toolCallId: string; toolName: string; input: string };

export const USAGE: Usage = {
	inputTokens: { total: 10, noCache: 10, cacheRead: undefined, cacheWrite: undefined },
	outputTokens: { total: 5, text: 5, reasoning: undefined },
};

// Each text arrives in two deltas, so the tests check that the client joins
// them.
export function partsOf(content: Content): StreamPart[] {
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

export function stream(parts: StreamPart[]): StreamResult {
	return { stream: simulateReadableStream({ chunks: parts, initialDelayInMs: null, chunkDelayInMs: null }) };
}

export function reply(content: Content[], usage: Usage = USAGE): StreamResult {
	return stream([
		{ type: "stream-start", warnings: [] },
		...content.flatMap(partsOf),
		{ type: "finish", finishReason: { unified: "stop", raw: undefined }, usage },
	]);
}

export function done(): StreamResult {
	return reply([{ type: "text", text: "Done." }]);
}

export function replying(make: () => StreamResult): MockLanguageModelV4 {
	return new MockLanguageModelV4({ doStream: () => Promise.resolve(make()) });
}

// A model that gives each reply in turn, one per call.
export function scripted(replies: StreamResult[]): MockLanguageModelV4 {
	return new MockLanguageModelV4({ doStream: () => Promise.resolve(replies.shift() ?? done()) });
}
