// Looks up model prices in LiteLLM's public price file, which lists each
// provider's own prices with no markup.
// docs/design/core/model-client.md has the design.

import { z } from "zod";
import type { Price, Provider } from "../config.js";
import type { Fetch } from "./list-models.js";

export const PRICES_URL = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json";

// The file lists thousands of models, so each entry is checked only when the
// picker asks for it.
export type PriceList = Record<string, unknown>;

export type PricesResult =
	| { ok: true; prices: PriceList }
	| { ok: false; error: string };

const ENTRY = z.object({
	input_cost_per_token: z.number().nonnegative(),
	output_cost_per_token: z.number().nonnegative(),
});

// The file names Google's models with a "gemini/" prefix, and the others by
// the provider's own ID.
const PREFIXES: Record<Provider, string> = {
	anthropic: "",
	openai: "",
	google: "gemini/",
};

export async function fetchPrices(fetchFile: Fetch = fetch): Promise<PricesResult> {
	try {
		const response = await fetchFile(PRICES_URL, { headers: {} });

		if (!response.ok) {
			return { ok: false, error: `The price list answered with ${response.status}` };
		}

		return { ok: true, prices: z.record(z.string(), z.unknown()).parse(await response.json()) };
	} catch (error) {
		// fetch and zod throw only errors.
		return { ok: false, error: `Couldn't read the price list: ${(error as Error).message}` };
	}
}

// Rounds away the float error that the conversion from a price per token adds.
function perMillion(perToken: number): number {
	return Number((perToken * 1_000_000).toFixed(6));
}

// Undefined when the list has no price for the model.
export function priceFor(prices: PriceList, provider: Provider, id: string): Price | undefined {
	const entry = ENTRY.safeParse(prices[`${PREFIXES[provider]}${id}`]);

	return entry.success
		? { input: perMillion(entry.data.input_cost_per_token), output: perMillion(entry.data.output_cost_per_token) }
		: undefined;
}

export function priceLabel(price: Price | undefined): string {
	return price === undefined || price.input === "" || price.output === ""
		? "no price"
		: `$${price.input} in, $${price.output} out per million tokens`;
}
