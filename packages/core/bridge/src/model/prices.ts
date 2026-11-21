// Looks up model prices in LiteLLM's public price file, which lists each
// provider's own prices with no markup.
// docs/design/core/model-client.md has the design.

import fs from "node:fs";
import path from "node:path";
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

const PRICE_LIST = z.record(z.string(), z.unknown());

// Prices change rarely, and the file is a few megabytes.
export const CACHE_MAX_AGE_MS = 24 * 60 * 60 * 1000;

export async function fetchPrices(fetchFile: Fetch = fetch): Promise<PricesResult> {
	try {
		const response = await fetchFile(PRICES_URL, { headers: {} });

		if (!response.ok) {
			return { ok: false, error: `The price list answered with ${response.status}` };
		}

		return { ok: true, prices: PRICE_LIST.parse(await response.json()) };
	} catch (error) {
		// fetch and zod throw only errors.
		return { ok: false, error: `Couldn't read the price list: ${(error as Error).message}` };
	}
}

// The cache sits in the config file's folder, beside the logs.
export function pricesCachePath(configPath: string): string {
	return path.join(path.dirname(configPath), "cache", "prices.json");
}

// The cached list and when it was saved, or undefined when there is none or
// it can't be read.
function readCache(file: string): { prices: PriceList; savedAt: number } | undefined {
	try {
		return { prices: PRICE_LIST.parse(JSON.parse(fs.readFileSync(file, "utf8"))), savedAt: fs.statSync(file).mtimeMs };
	} catch {
		return undefined;
	}
}

// A cache that can't be written only means the next start fetches again.
function writeCache(file: string, prices: PriceList): void {
	try {
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, JSON.stringify(prices));
	} catch {
		// Nothing to do.
	}
}

// Uses the cache while it is less than a day old. Otherwise fetches the list
// and saves it, or falls back to an old cache when the fetch fails.
export async function cachedPrices(file: string, fetchFile: Fetch = fetch, now = Date.now()): Promise<PricesResult> {
	const cached = readCache(file);

	if (cached !== undefined && now - cached.savedAt < CACHE_MAX_AGE_MS) {
		return { ok: true, prices: cached.prices };
	}

	const fetched = await fetchPrices(fetchFile);

	if (fetched.ok) {
		writeCache(file, fetched.prices);

		return fetched;
	}

	return cached === undefined ? fetched : { ok: true, prices: cached.prices };
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
