// Tests for model/usage.ts.

import { describe, expect, test, vi } from "vitest";
import { type ModelSetting, NO_PRICE, type Price } from "../../src/config.js";
import { Logger } from "../../src/log.js";
import type { Usage } from "../../src/model/client.js";
import { callCost, logModelCall } from "../../src/model/usage.js";

const PRICE: Price = { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 };

function usage(inputTokens: number, outputTokens: number, cacheReadTokens = 0, cacheWriteTokens = 0): Usage {
	return { inputTokens, cacheReadTokens, cacheWriteTokens, outputTokens };
}

describe("callCost", () => {
	test("prices input and output per million tokens", () => {
		expect(callCost(usage(200_000, 10_000), PRICE)).toBeCloseTo(0.75);
	});

	test("prices cache reads and writes at their own prices", () => {
		// 100,000 uncached at $3, 80,000 read at $0.30, 20,000 written at
		// $3.75, and 10,000 output at $15.
		expect(callCost(usage(200_000, 10_000, 80_000, 20_000), PRICE)).toBeCloseTo(0.3 + 0.024 + 0.075 + 0.15);
	});

	test("counts cached tokens with no cache price as plain input", () => {
		const noCachePrices: Price = { ...PRICE, cacheRead: "", cacheWrite: "" };

		expect(callCost(usage(200_000, 10_000, 80_000, 20_000), noCachePrices)).toBeCloseTo(0.75);
	});

	test("is undefined when the call used input or output with no price", () => {
		expect(callCost(usage(200_000, 10_000), NO_PRICE)).toBeUndefined();
		expect(callCost(usage(200_000, 10_000), { ...PRICE, input: "" })).toBeUndefined();
		expect(callCost(usage(200_000, 10_000), { ...PRICE, output: "" })).toBeUndefined();
	});

	test("needs no output price for a call with no output", () => {
		expect(callCost(usage(200_000, 0), { ...PRICE, output: "" })).toBeCloseTo(0.6);
	});

	test("counts a free price as no cost", () => {
		expect(callCost(usage(200_000, 10_000), { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 })).toBe(0);
	});
});

describe("logModelCall", () => {
	const MODEL: ModelSetting = { mode: "api-key", provider: "anthropic", id: "claude-x", effort: "", price: PRICE };

	test("logs the tokens and the cost at the decisions level", () => {
		const logger = new Logger("debug", "");
		const decision = vi.spyOn(logger, "decision");

		logModelCall(logger, MODEL, usage(200_000, 10_000));

		expect(decision).toHaveBeenCalledWith("model_call", "claude-x: 200000 input and 10000 output tokens, $0.7500", {
			provider: "anthropic",
			id: "claude-x",
			inputTokens: 200_000,
			cacheReadTokens: 0,
			cacheWriteTokens: 0,
			outputTokens: 10_000,
			cost: 0.75,
		});
	});

	test("names the cached tokens when there are some", () => {
		const logger = new Logger("debug", "");
		const decision = vi.spyOn(logger, "decision");

		logModelCall(logger, MODEL, usage(200_000, 10_000, 80_000, 20_000));

		expect(decision).toHaveBeenCalledWith(
			"model_call",
			"claude-x: 200000 input (80000 read from the cache, 20000 written to it) and 10000 output tokens, $0.5490",
			expect.objectContaining({ cacheReadTokens: 80_000, cacheWriteTokens: 20_000 }),
		);
	});

	test("logs only the tokens without a price", () => {
		const logger = new Logger("debug", "");
		const decision = vi.spyOn(logger, "decision");

		logModelCall(logger, { ...MODEL, price: NO_PRICE }, usage(200_000, 10_000));

		expect(decision).toHaveBeenCalledWith("model_call", "claude-x: 200000 input and 10000 output tokens", expect.objectContaining({ cost: undefined }));
	});
});
