// Tests for model/usage.ts.

import { describe, expect, test, vi } from "vitest";
import { type ModelSetting, NO_PRICE } from "../../src/config.js";
import { Logger } from "../../src/log.js";
import { callCost, logModelCall } from "../../src/model/usage.js";

const USAGE = { inputTokens: 200_000, outputTokens: 10_000 };

describe("callCost", () => {
	test("prices input and output per million tokens", () => {
		expect(callCost(USAGE, { input: 3, output: 15 })).toBeCloseTo(0.75);
	});

	test("is undefined when either price is blank", () => {
		expect(callCost(USAGE, NO_PRICE)).toBeUndefined();
		expect(callCost(USAGE, { input: 3, output: "" })).toBeUndefined();
		expect(callCost(USAGE, { input: "", output: 15 })).toBeUndefined();
	});

	test("counts a free price as no cost", () => {
		expect(callCost(USAGE, { input: 0, output: 0 })).toBe(0);
	});
});

describe("logModelCall", () => {
	const MODEL: ModelSetting = { provider: "anthropic", id: "claude-x", effort: "", price: { input: 3, output: 15 } };

	test("logs the tokens and the cost at the decisions level", () => {
		const logger = new Logger("debug", "");
		const decision = vi.spyOn(logger, "decision");

		logModelCall(logger, MODEL, USAGE);

		expect(decision).toHaveBeenCalledWith("model_call", "claude-x: 200000 input and 10000 output tokens, $0.7500", {
			provider: "anthropic",
			id: "claude-x",
			inputTokens: 200_000,
			outputTokens: 10_000,
			cost: 0.75,
		});
	});

	test("logs only the tokens without a price", () => {
		const logger = new Logger("debug", "");
		const decision = vi.spyOn(logger, "decision");

		logModelCall(logger, { ...MODEL, price: NO_PRICE }, USAGE);

		expect(decision).toHaveBeenCalledWith("model_call", "claude-x: 200000 input and 10000 output tokens", expect.objectContaining({ cost: undefined }));
	});
});
