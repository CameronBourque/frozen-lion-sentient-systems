// Tests for agents/spend.ts.

import { describe, expect, test } from "vitest";
import { addSpend, describeSpend, noSpend, reachedSpendLimit, spendWarnings } from "../../src/agents/spend.js";
import { DEFAULT_LIMITS, type Limits, NO_PRICE, type Price } from "../../src/config.js";

const USAGE = { inputTokens: 1000, cacheReadTokens: 0, cacheWriteTokens: 0, outputTokens: 500 };
const PRICE: Price = { input: 3, output: 15, cacheRead: "", cacheWrite: "" };

function limits(set: Partial<Limits>): Limits {
	return { ...DEFAULT_LIMITS, ...set };
}

describe("addSpend", () => {
	test("adds input and output tokens, and the cost at the model's price", () => {
		const spend = noSpend();

		addSpend(spend, USAGE, PRICE);
		addSpend(spend, USAGE, PRICE);

		expect(spend.tokens).toBe(3000);
		expect(spend.cost).toBeCloseTo(0.021);
	});

	test("adds no cost with no price", () => {
		const spend = noSpend();

		addSpend(spend, USAGE, NO_PRICE);

		expect(spend).toEqual({ tokens: 1500, cost: 0 });
	});
});

describe("reachedSpendLimit", () => {
	const spend = { tokens: 1500, cost: 0.0105 };

	test("returns no limit when none is set", () => {
		expect(reachedSpendLimit(spend, DEFAULT_LIMITS, "turn")).toBeUndefined();
		expect(reachedSpendLimit(spend, DEFAULT_LIMITS, "run")).toBeUndefined();
	});

	test("reaches a token limit at its value, not below it", () => {
		expect(reachedSpendLimit(spend, limits({ tokensPerTurn: 1500 }), "turn")).toBe("tokensPerTurn");
		expect(reachedSpendLimit(spend, limits({ tokensPerTurn: 1501 }), "turn")).toBeUndefined();
	});

	test("reaches a cost limit at its value, not below it", () => {
		expect(reachedSpendLimit(spend, limits({ costPerRun: 0.01 }), "run")).toBe("costPerRun");
		expect(reachedSpendLimit(spend, limits({ costPerRun: 0.02 }), "run")).toBeUndefined();
	});

	test("checks only the scope's limits, and the token limit wins over the cost limit", () => {
		expect(reachedSpendLimit(spend, limits({ tokensPerRun: 1 }), "turn")).toBeUndefined();
		expect(reachedSpendLimit(spend, limits({ tokensPerTurn: 1, costPerTurn: 0.01 }), "turn")).toBe("tokensPerTurn");
	});
});

describe("describeSpend", () => {
	test("gives the tokens, and the cost when there is one", () => {
		expect(describeSpend({ tokens: 1500, cost: 0.0105 })).toBe("1500 tokens and $0.0105");
		expect(describeSpend({ tokens: 1500, cost: 0 })).toBe("1500 tokens");
	});
});

describe("spendWarnings", () => {
	test("warns when no spending limit is set", () => {
		expect(spendWarnings(DEFAULT_LIMITS, PRICE)).toEqual([expect.stringContaining("No spending limit is set") as unknown]);
	});

	test("warns about each cost limit with no price, and not about token limits", () => {
		expect(spendWarnings(limits({ tokensPerRun: 1000, costPerTurn: 1, costPerRun: 5 }), NO_PRICE)).toEqual([
			expect.stringMatching(/^limits\.costPerTurn needs the input and output prices/) as unknown,
			expect.stringMatching(/^limits\.costPerRun needs the input and output prices/) as unknown,
		]);
		expect(spendWarnings(limits({ costPerRun: 5 }), { ...PRICE, output: "" })).toHaveLength(1);
	});

	test("has no warning for limits that can apply", () => {
		expect(spendWarnings(limits({ tokensPerRun: 1000 }), NO_PRICE)).toEqual([]);
		expect(spendWarnings(limits({ costPerRun: 5 }), PRICE)).toEqual([]);
	});
});
