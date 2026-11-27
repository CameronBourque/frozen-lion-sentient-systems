// Looks up facts about each model, such as its price, in OpenRouter's public
// model list, which gives each provider's own prices with no markup.
// docs/design/core/picker.md has the design.

import fs from "node:fs";
import path from "node:path";
import { z } from "zod";
import { EFFORTS, type Effort, type Price, type Provider, UNSET } from "../config.js";
import type { Fetch } from "./list-models.js";
import { hasPrice } from "./usage.js";

export const MODELS_URL = "https://openrouter.ai/api/v1/models";

// The list as OpenRouter sends it. Each entry is checked only when the picker
// asks for it, so one odd entry can't spoil the rest.
const MODEL_LIST = z.object({
	data: z.array(z.object({ id: z.string() }).loose()),
});

type ModelList = z.infer<typeof MODEL_LIST>;

// Each model's entry, by provider and ID. See factKey.
export type Facts = Record<string, unknown>;

export type FactsResult =
	| { ok: true; facts: Facts }
	| { ok: false; error: string };

// OpenRouter gives prices as strings of US dollars per token.
const PER_TOKEN = z.string().transform(Number).pipe(z.number().nonnegative());

// A model without prompt caching has no cache prices.
const PRICED = z.object({
	pricing: z.object({
		prompt: PER_TOKEN,
		completion: PER_TOKEN,
		input_cache_read: PER_TOKEN.optional(),
		input_cache_write: PER_TOKEN.optional(),
	}),
});

// Prices change rarely, and the list is about a megabyte.
export const CACHE_MAX_AGE_MS = 24 * 60 * 60 * 1000;

// OpenRouter names a model "anthropic/claude-opus-5.5" where Anthropic's API
// says "claude-opus-5-5", so a dot and a dash count as the same.
function factKey(provider: string, id: string): string {
	return `${provider}/${id.toLowerCase().replaceAll(".", "-")}`;
}

// Anthropic's list names older models with a release date, such as
// claude-haiku-4-5-20251001, where OpenRouter names them without it.
const RELEASE_DATE = /-\d{8}$/;

// A model's entry, by its ID, or by its ID without a release date.
function entryFor(facts: Facts, provider: Provider, id: string): unknown {
	return facts[factKey(provider, id)] ?? facts[factKey(provider, id.replace(RELEASE_DATE, ""))];
}

// Indexes each model by provider and ID. Leaves out variants, whose IDs end in
// a colon and a tag, since they name the same model.
function indexFacts(list: ModelList): Facts {
	return Object.fromEntries(list.data
		.filter(({ id }) => !id.includes(":"))
		.map((entry) => {
			const [provider, ...rest] = entry.id.split("/");

			return [factKey(provider, rest.join("/")), entry];
		}));
}

export async function fetchFacts(fetchFile: Fetch = fetch): Promise<FactsResult> {
	try {
		const response = await fetchFile(MODELS_URL, { headers: {} });

		if (!response.ok) {
			return { ok: false, error: `OpenRouter's model list answered with ${response.status}` };
		}

		return { ok: true, facts: indexFacts(MODEL_LIST.parse(await response.json())) };
	} catch (error) {
		// fetch and zod throw only errors.
		return { ok: false, error: `Couldn't read OpenRouter's model list: ${(error as Error).message}` };
	}
}

// The cache sits in the config file's folder, beside the logs.
export function factsCachePath(configPath: string): string {
	return path.join(path.dirname(configPath), "cache", "models.json");
}

// The cached facts and when they were saved, or undefined when there is no
// cache or it can't be read.
function readCache(file: string): { facts: Facts; savedAt: number } | undefined {
	try {
		return { facts: z.record(z.string(), z.unknown()).parse(JSON.parse(fs.readFileSync(file, "utf8"))), savedAt: fs.statSync(file).mtimeMs };
	} catch {
		return undefined;
	}
}

// A cache that can't be written only means the next start fetches again.
function writeCache(file: string, facts: Facts): void {
	try {
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, JSON.stringify(facts));
	} catch {
		// Nothing to do.
	}
}

// Uses the cache while it is less than a day old. Otherwise fetches the list
// and saves it, or falls back to an old cache when the fetch fails.
export async function cachedFacts(file: string, fetchFile: Fetch = fetch, now = Date.now()): Promise<FactsResult> {
	const cached = readCache(file);

	if (cached !== undefined && now - cached.savedAt < CACHE_MAX_AGE_MS) {
		return { ok: true, facts: cached.facts };
	}

	const fetched = await fetchFacts(fetchFile);

	if (fetched.ok) {
		writeCache(file, fetched.facts);

		return fetched;
	}

	return cached === undefined ? fetched : { ok: true, facts: cached.facts };
}

// Rounds away the float error that the conversion from a price per token adds.
function perMillion(perToken: number): number {
	return Number((perToken * 1_000_000).toFixed(6));
}

function optionalPerMillion(perToken: number | undefined): number {
	return perToken === undefined ? UNSET : perMillion(perToken);
}

// Undefined when the list has no price for the model. A cache price the list
// doesn't give stays unset.
export function priceFor(facts: Facts, provider: Provider, id: string): Price | undefined {
	const entry = PRICED.safeParse(entryFor(facts, provider, id));

	if (!entry.success) {
		return undefined;
	}

	const { pricing } = entry.data;

	return {
		input: perMillion(pricing.prompt),
		output: perMillion(pricing.completion),
		cacheRead: optionalPerMillion(pricing.input_cache_read),
		cacheWrite: optionalPerMillion(pricing.input_cache_write),
	};
}

const WITH_PARAMETERS = z.object({
	supported_parameters: z.array(z.string()),
});

// False for a model OpenRouter doesn't list, such as a speech or embedding
// model, or one that it lists without tools, such as an image model.
export function callsTools(facts: Facts, provider: Provider, id: string): boolean {
	const entry = WITH_PARAMETERS.safeParse(entryFor(facts, provider, id));

	return entry.success && entry.data.supported_parameters.includes("tools");
}

const WITH_REASONING = z.object({
	reasoning: z.object({
		mandatory: z.boolean().default(false),
		supported_efforts: z.array(z.string()).optional(),
		default_effort: z.string().optional(),
	}).nullish(),
});

export interface EffortChoices {
	efforts: Effort[];
	// The level the provider uses for provider-default, when OpenRouter says.
	defaultEffort?: string;
}

// The effort levels to offer, in the order of EFFORTS:
// - every level for a model OpenRouter doesn't list,
// - only provider-default for a model without reasoning,
// - provider-default and the model's levels, when OpenRouter lists them,
// - otherwise every level, but none when reasoning can't be turned off.
export function effortsFor(facts: Facts, provider: Provider, id: string): EffortChoices {
	const entry = WITH_REASONING.safeParse(entryFor(facts, provider, id));

	if (!entry.success) {
		return { efforts: EFFORTS };
	}

	const { reasoning } = entry.data;

	if (reasoning === undefined || reasoning === null) {
		return { efforts: ["provider-default"] };
	}

	const listed = reasoning.supported_efforts;
	const offered = EFFORTS.filter((effort) => listed === undefined
		? !(effort === "none" && reasoning.mandatory)
		: effort === "provider-default" || listed.includes(effort));

	return { efforts: offered, defaultEffort: reasoning.default_effort };
}

export function priceLabel(price: Price | undefined): string {
	return price === undefined || !hasPrice(price)
		? "no price"
		: `$${price.input} in, $${price.output} out per million tokens`;
}
