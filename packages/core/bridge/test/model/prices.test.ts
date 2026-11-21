// Tests for model/prices.ts, with a fake fetch in place of the price file.

import { describe, expect, test } from "vitest";
import { NO_PRICE } from "../../src/config.js";
import type { Fetch } from "../../src/model/list-models.js";
import { PRICES_URL, fetchPrices, priceFor, priceLabel } from "../../src/model/prices.js";

const PRICES = {
	"sample_spec": { input_cost_per_token: "a number" },
	"claude-a": { input_cost_per_token: 0.000003, output_cost_per_token: 0.000015 },
	"gemini/gemini-a": { input_cost_per_token: 0.00000125, output_cost_per_token: 0.00001 },
	"gpt-a": { input_cost_per_token: 0.0000025 },
};

describe("fetchPrices", () => {
	test("reads the price file", async () => {
		const urls: string[] = [];

		const fetchFile: Fetch = (url) => {
			urls.push(url);

			return Promise.resolve(new Response(JSON.stringify(PRICES)));
		};

		expect(await fetchPrices(fetchFile)).toEqual({ ok: true, prices: PRICES });
		expect(urls).toEqual([PRICES_URL]);
	});

	test("names the status when the file can't be read", async () => {
		const missing: Fetch = () => Promise.resolve(new Response("", { status: 503 }));

		expect(await fetchPrices(missing)).toEqual({ ok: false, error: "The price list answered with 503" });
	});

	test("names the reason when the request fails", async () => {
		const offline: Fetch = () => Promise.reject(new Error("getaddrinfo ENOTFOUND"));

		expect(await fetchPrices(offline)).toEqual({ ok: false, error: "Couldn't read the price list: getaddrinfo ENOTFOUND" });
	});

	test("fails on a file that isn't a list of models", async () => {
		const wrong: Fetch = () => Promise.resolve(new Response("[1, 2]"));

		expect(await fetchPrices(wrong)).toMatchObject({ ok: false, error: expect.stringMatching(/^Couldn't read the price list: /) as unknown });
	});
});

describe("priceFor", () => {
	test("converts the price per token to the price per million tokens", () => {
		expect(priceFor(PRICES, "anthropic", "claude-a")).toEqual({ input: 3, output: 15 });
	});

	test("finds a Google model under its prefix", () => {
		expect(priceFor(PRICES, "google", "gemini-a")).toEqual({ input: 1.25, output: 10 });
	});

	test("has no price for a model that isn't listed, or that lacks a price", () => {
		expect(priceFor(PRICES, "openai", "gpt-b")).toBeUndefined();
		expect(priceFor(PRICES, "openai", "gpt-a")).toBeUndefined();
		expect(priceFor(PRICES, "openai", "sample_spec")).toBeUndefined();
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
