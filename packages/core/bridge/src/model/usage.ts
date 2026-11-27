// Logs each model call's tokens, and its cost when the model has a price.
// docs/design/core/model-client.md has the design.

import { type ModelSetting, type Price, UNSET } from "../config.js";
import type { Logger } from "../log.js";
import type { Usage } from "./client.js";

// The cache prices are optional, since they fall back to the input price.
export function hasPrice(price: Price): boolean {
	return price.input !== UNSET && price.output !== UNSET;
}

// Each kind of token, its count, and its price per million. A cache read or
// write with no cache price counts as plain input.
function charges(usage: Usage, price: Price): [number, number][] {
	const uncached = usage.inputTokens - usage.cacheReadTokens - usage.cacheWriteTokens;

	return [
		[uncached, price.input],
		[usage.cacheReadTokens, price.cacheRead === UNSET ? price.input : price.cacheRead],
		[usage.cacheWriteTokens, price.cacheWrite === UNSET ? price.input : price.cacheWrite],
		[usage.outputTokens, price.output],
	];
}

// Undefined when the call used input or output with no price.
export function callCost(usage: Usage, price: Price): number | undefined {
	let cost = 0;

	for (const [tokens, perMillion] of charges(usage, price)) {
		if (tokens === 0) {
			continue;
		}

		if (perMillion === UNSET) {
			return undefined;
		}

		cost += tokens * perMillion / 1_000_000;
	}

	return cost;
}

export function logModelCall(logger: Logger, model: ModelSetting, usage: Usage): void {
	const cost = callCost(usage, model.price);
	const cached = usage.cacheReadTokens + usage.cacheWriteTokens;
	const input = `${usage.inputTokens} input${cached === 0 ? "" : ` (${usage.cacheReadTokens} read from the cache, ${usage.cacheWriteTokens} written to it)`}`;
	const tokens = `${input} and ${usage.outputTokens} output tokens`;

	logger.decision("model_call", `${model.id}: ${tokens}${cost === undefined ? "" : `, $${cost.toFixed(4)}`}`, {
		provider: model.provider,
		id: model.id,
		...usage,
		cost,
	});
}
