// Logs each model call's tokens, and its cost when the model has a price.
// docs/design/core/model-client.md has the design.

import type { ModelSetting, Price } from "../config.js";
import type { Logger } from "../log.js";
import type { Usage } from "./client.js";

// Undefined when either price is blank, because half a price gives a wrong
// cost. Cached input counts at the full input price, so the cost can run a
// little high.
export function callCost(usage: Usage, price: Price): number | undefined {
	if (price.input === "" || price.output === "") {
		return undefined;
	}

	return (usage.inputTokens * price.input + usage.outputTokens * price.output) / 1_000_000;
}

export function logModelCall(logger: Logger, model: ModelSetting, usage: Usage): void {
	const cost = callCost(usage, model.price);
	const tokens = `${usage.inputTokens} input and ${usage.outputTokens} output tokens`;

	logger.decision("model_call", `${model.id}: ${tokens}${cost === undefined ? "" : `, $${cost.toFixed(4)}`}`, {
		provider: model.provider,
		id: model.id,
		...usage,
		cost,
	});
}
