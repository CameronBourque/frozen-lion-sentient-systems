// What the model calls spend in tokens and dollars, and the spending limit the
// spend reaches. docs/design/agents/turn-loop/stopping.md has the design.

import { type Limits, type Price, UNSET } from "../config.js";
import type { Usage } from "../model/client.js";
import { callCost, hasPrice } from "../model/usage.js";

// cost counts only the calls with a price.
export interface Spend {
	tokens: number;
	cost: number;
}

// The token limit and the cost limit, for a turn and for a run.
const SPEND_LIMITS = {
	turn: ["tokensPerTurn", "costPerTurn"],
	run: ["tokensPerRun", "costPerRun"],
} as const;

export type SpendScope = keyof typeof SPEND_LIMITS;

export type SpendLimit = typeof SPEND_LIMITS[SpendScope][number];

export function noSpend(): Spend {
	return { tokens: 0, cost: 0 };
}

export function addSpend(spend: Spend, usage: Usage, price: Price): void {
	spend.tokens += usage.inputTokens + usage.outputTokens;
	spend.cost += callCost(usage, price) ?? 0;
}

// Every check goes through here, since a spend is always at or above UNSET.
function reaches(spent: number, limit: number): boolean {
	return limit !== UNSET && spent >= limit;
}

// The token limit wins when the spend reaches both.
export function reachedSpendLimit(spend: Spend, limits: Limits, scope: SpendScope): SpendLimit | undefined {
	const [tokens, cost] = SPEND_LIMITS[scope];

	if (reaches(spend.tokens, limits[tokens])) {
		return tokens;
	}

	return reaches(spend.cost, limits[cost]) ? cost : undefined;
}

export function describeSpend(spend: Spend): string {
	return `${spend.tokens} tokens${spend.cost > 0 ? ` and $${spend.cost.toFixed(4)}` : ""}`;
}

// A cost limit with no price never counts a dollar, so it never stops the
// agent. With no limit at all, the agent spends until the stop key.
export function spendWarnings(limits: Limits, price: Price): string[] {
	const set = Object.values(SPEND_LIMITS).flat().filter((limit) => limits[limit] !== UNSET);

	if (set.length === 0) {
		return ["No spending limit is set, so the agents spend until you stop the bridge. Set one in limits in the config file"];
	}

	if (hasPrice(price)) {
		return [];
	}

	const costs = new Set<SpendLimit>(Object.values(SPEND_LIMITS).map(([, cost]) => cost));

	return set.filter((limit) => costs.has(limit)).map((limit) => `limits.${limit} needs the input and output prices in model.price, so it won't stop the agent until you set them`);
}
