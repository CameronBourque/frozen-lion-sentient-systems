// Tests for model/model-facts.ts, with a fake fetch in place of OpenRouter's
// model list, and the cache in a temporary folder.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { EFFORTS, NO_PRICE } from "../../src/config.js";
import type { Fetch } from "../../src/model/list-models.js";
import { MODELS_URL, cachedFacts, callsTools, effortsFor, factsCachePath, fetchFacts, priceFor, priceLabel } from "../../src/model/model-facts.js";

const CLAUDE = { id: "anthropic/claude-a.5", pricing: { prompt: "0.000003", completion: "0.000015" } };
const GEMINI = { id: "google/gemini-a", pricing: { prompt: "0.00000125", completion: "0.00001" } };
const VARIABLE = { id: "openai/gpt-router", pricing: { prompt: "-1", completion: "-1" } };
const NO_PRICING = { id: "openai/gpt-a" };
const BATCH = { id: "anthropic/claude-a.5:batch", pricing: { prompt: "0.0000015", completion: "0.0000075" } };

const LIST = { data: [CLAUDE, GEMINI, VARIABLE, NO_PRICING, BATCH] };

// The list's facts, as fetchFacts indexes them.
const FACTS = {
	"anthropic/claude-a-5": CLAUDE,
	"google/gemini-a": GEMINI,
	"openai/gpt-router": VARIABLE,
	"openai/gpt-a": NO_PRICING,
};

const answer: Fetch = () => Promise.resolve(new Response(JSON.stringify(LIST)));

describe("fetchFacts", () => {
	test("indexes each model by provider and ID, with dots as dashes", async () => {
		const urls: string[] = [];

		const fetchFile: Fetch = (url) => {
			urls.push(url);

			return answer(url, { headers: {} });
		};

		expect(await fetchFacts(fetchFile)).toEqual({ ok: true, facts: FACTS });
		expect(urls).toEqual([MODELS_URL]);
	});

	test("names the status when the list can't be read", async () => {
		const missing: Fetch = () => Promise.resolve(new Response("", { status: 503 }));

		expect(await fetchFacts(missing)).toEqual({ ok: false, error: "OpenRouter's model list answered with 503" });
	});

	test("names the reason when the request fails", async () => {
		const offline: Fetch = () => Promise.reject(new Error("getaddrinfo ENOTFOUND"));

		expect(await fetchFacts(offline)).toEqual({ ok: false, error: "Couldn't read OpenRouter's model list: getaddrinfo ENOTFOUND" });
	});

	test("fails on an answer that isn't a model list", async () => {
		const wrong: Fetch = () => Promise.resolve(new Response("[1, 2]"));

		expect(await fetchFacts(wrong)).toMatchObject({ ok: false, error: expect.stringMatching(/^Couldn't read OpenRouter's model list: /) as unknown });
	});
});

describe("priceFor", () => {
	test("converts the price per token to the price per million tokens", () => {
		expect(priceFor(FACTS, "anthropic", "claude-a-5")).toEqual({ input: 3, output: 15 });
	});

	test("finds a model by its ID without the release date", () => {
		expect(priceFor(FACTS, "anthropic", "claude-a-5-20260101")).toEqual({ input: 3, output: 15 });
		expect(priceFor(FACTS, "anthropic", "claude-a-5-2026")).toBeUndefined();
	});

	test("finds a Google model", () => {
		expect(priceFor(FACTS, "google", "gemini-a")).toEqual({ input: 1.25, output: 10 });
	});

	test("has no price for a model that isn't listed, has no price, or has a price that varies", () => {
		expect(priceFor(FACTS, "openai", "gpt-b")).toBeUndefined();
		expect(priceFor(FACTS, "openai", "gpt-a")).toBeUndefined();
		expect(priceFor(FACTS, "openai", "gpt-router")).toBeUndefined();
	});
});

describe("callsTools", () => {
	const TOOL_FACTS = {
		"openai/gpt-a": { supported_parameters: ["tools", "tool_choice"] },
		"openai/gpt-image": { supported_parameters: ["response_format"] },
		"openai/gpt-odd": {},
	};

	test("is true for a model that lists tools", () => {
		expect(callsTools(TOOL_FACTS, "openai", "gpt-a")).toBe(true);
	});

	test("is false for a model without tools, without parameters, or not listed", () => {
		expect(callsTools(TOOL_FACTS, "openai", "gpt-image")).toBe(false);
		expect(callsTools(TOOL_FACTS, "openai", "gpt-odd")).toBe(false);
		expect(callsTools(TOOL_FACTS, "openai", "whisper-1")).toBe(false);
	});
});

describe("effortsFor", () => {
	const EFFORT_FACTS = {
		"anthropic/claude-big": { reasoning: { mandatory: true, supported_efforts: ["max", "xhigh", "high", "medium", "low"], default_effort: "high" } },
		"anthropic/claude-small": { reasoning: { mandatory: false, supported_efforts: ["max", "high", "low", "none", "turbo"] } },
		"openai/gpt-plain": { reasoning: null },
		"openai/gpt-quiet": {},
		"google/gemini-open": { reasoning: { mandatory: false } },
		"google/gemini-always": { reasoning: { mandatory: true } },
	};

	test("offers provider-default and the listed levels, in the usual order, with the default", () => {
		expect(effortsFor(EFFORT_FACTS, "anthropic", "claude-big")).toEqual({
			efforts: ["provider-default", "low", "medium", "high", "xhigh", "max"],
			defaultEffort: "high",
		});
	});

	test("leaves out a listed level the SDK doesn't have", () => {
		expect(effortsFor(EFFORT_FACTS, "anthropic", "claude-small").efforts).toEqual(["provider-default", "none", "low", "high", "max"]);
	});

	test("offers only provider-default for a model without reasoning", () => {
		expect(effortsFor(EFFORT_FACTS, "openai", "gpt-plain")).toEqual({ efforts: ["provider-default"] });
		expect(effortsFor(EFFORT_FACTS, "openai", "gpt-quiet")).toEqual({ efforts: ["provider-default"] });
	});

	test("offers every level when the levels aren't listed, but none only when reasoning can be off", () => {
		expect(effortsFor(EFFORT_FACTS, "google", "gemini-open").efforts).toEqual(EFFORTS);
		expect(effortsFor(EFFORT_FACTS, "google", "gemini-always").efforts).toEqual(EFFORTS.filter((effort) => effort !== "none"));
	});

	test("offers every level for a model OpenRouter doesn't list", () => {
		expect(effortsFor(EFFORT_FACTS, "openai", "gpt-unknown")).toEqual({ efforts: EFFORTS });
	});
});

describe("priceLabel", () => {
	test("names both prices", () => {
		expect(priceLabel({ input: 1.25, output: 10 })).toBe("$1.25 in, $10 out per million tokens");
	});

	test("says there is no price when either is blank", () => {
		expect(priceLabel(undefined)).toBe("no price");
		expect(priceLabel(NO_PRICE)).toBe("no price");
		expect(priceLabel({ input: 1, output: "" })).toBe("no price");
	});
});

describe("cachedFacts", () => {
	const NOW = Date.parse("2026-11-20T12:00:00Z");
	const HOUR = 60 * 60 * 1000;
	let folder: string;
	let file: string;
	let fetches: number;

	// Answers with the list, and counts the fetches.
	const fetchFile: Fetch = (url, init) => {
		fetches += 1;

		return answer(url, init);
	};

	const offline: Fetch = () => Promise.reject(new Error("offline"));

	// Saves a cache whose file time is a number of hours before NOW.
	function saveCache(facts: unknown, hoursOld: number): void {
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, JSON.stringify(facts));

		const time = new Date(NOW - hoursOld * HOUR);

		fs.utimesSync(file, time, time);
	}

	beforeEach(() => {
		folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
		file = factsCachePath(path.join(folder, "sentient-systems.yaml"));
		fetches = 0;
	});

	afterEach(() => {
		fs.rmSync(folder, { recursive: true, force: true });
	});

	test("keeps the cache in the config file's folder", () => {
		expect(file).toBe(path.join(folder, "cache", "models.json"));
	});

	test("fetches and saves the facts when there is no cache", async () => {
		expect(await cachedFacts(file, fetchFile, NOW)).toEqual({ ok: true, facts: FACTS });
		expect(fetches).toBe(1);
		expect(JSON.parse(fs.readFileSync(file, "utf8"))).toEqual(FACTS);
	});

	test("uses a cache less than a day old without fetching", async () => {
		saveCache({ "openai/cached": {} }, 23);

		expect(await cachedFacts(file, fetchFile, NOW)).toEqual({ ok: true, facts: { "openai/cached": {} } });
		expect(fetches).toBe(0);
	});

	test("fetches again when the cache is a day old", async () => {
		saveCache({ "openai/cached": {} }, 24);

		expect(await cachedFacts(file, fetchFile, NOW)).toEqual({ ok: true, facts: FACTS });
		expect(fetches).toBe(1);
	});

	test("falls back to an old cache when the fetch fails", async () => {
		saveCache({ "openai/cached": {} }, 48);

		expect(await cachedFacts(file, offline, NOW)).toEqual({ ok: true, facts: { "openai/cached": {} } });
	});

	test("fails when the fetch fails and there is no cache", async () => {
		expect(await cachedFacts(file, offline, NOW)).toEqual({ ok: false, error: "Couldn't read OpenRouter's model list: offline" });
	});

	test("fetches over a cache that isn't valid", async () => {
		saveCache([1, 2], 1);

		expect(await cachedFacts(file, fetchFile, NOW)).toEqual({ ok: true, facts: FACTS });
		expect(fetches).toBe(1);
	});

	test("still returns the facts when the cache can't be written", async () => {
		// A file where the cache folder should be stops the write.
		fs.writeFileSync(path.join(folder, "cache"), "");

		expect(await cachedFacts(file, fetchFile, NOW)).toEqual({ ok: true, facts: FACTS });
	});
});
