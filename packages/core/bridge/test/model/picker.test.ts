// Tests for model/picker.ts, with scripted answers in place of the menus and
// a fake model list.

import { describe, expect, test } from "vitest";
import { type Config, DEFAULT_MCP_PORT, type ModelSetting, NO_MODEL, NO_PRICE } from "../../src/config.js";
import type { ListResult } from "../../src/model/list-models.js";
import type { PricesResult } from "../../src/model/prices.js";
import { type PickerIo, pickModel, savedModelWarning } from "../../src/model/picker.js";

const MODELS: ListResult = {
	ok: true,
	models: [{ id: "model-a", name: "Model A" }, { id: "model-b", name: "model-b" }],
};

function configWith(keys: string[], model: ModelSetting = NO_MODEL): Config {
	return {
		schemaVersion: 1,
		logLevel: "decisions",
		providers: Object.fromEntries(keys.map((provider) => [provider, { apiKey: `${provider}-key` }])),
		model,
		mcpPort: DEFAULT_MCP_PORT,
	};
}

interface Asked {
	title: string;
	labels: string[];
	start: number;
}

// Answers each menu with the next row in the script, and records what it
// asked and warned.
// A list of results answers each list call in turn, and repeats the last.
function scriptedIo(rows: (number | undefined)[], list: ListResult | ListResult[] = MODELS, prices: PricesResult = { ok: true, prices: {} }) {
	const lists = Array.isArray(list) ? [...list] : [list];
	const asked: Asked[] = [];
	const warnings: string[] = [];
	const listed: string[] = [];
	const io: PickerIo = {
		ask: (title, labels, start) => {
			asked.push({ title, labels, start });

			return Promise.resolve(rows.shift());
		},
		list: (provider, apiKey) => {
			listed.push(`${provider} ${apiKey}`);

			return Promise.resolve(lists.length > 1 ? lists.shift() as ListResult : lists[0]);
		},
		prices: () => Promise.resolve(prices),
		warn: (text) => warnings.push(text),
	};

	return { io, asked, warnings, listed };
}

describe("pickModel", () => {
	test("asks for the provider, the model, and the effort", async () => {
		const { io, asked, listed } = scriptedIo([1, 1, 5]);

		expect(await pickModel(configWith(["anthropic", "openai"]), io)).toEqual({
			result: "picked",
			model: { provider: "openai", id: "model-b", effort: "high", price: NO_PRICE },
		});
		expect(asked.map(({ title }) => title)).toEqual(["Provider", "openai model", "Effort"]);
		expect(asked[0].labels).toEqual(["anthropic", "openai"]);
		expect(asked[1].labels).toEqual(["Model A (model-a), no price", "model-b, no price"]);
		expect(listed).toEqual(["openai openai-key"]);
	});

	test("skips the provider menu when only one provider has a key", async () => {
		const { io, asked } = scriptedIo([0, 0]);

		expect(await pickModel(configWith(["google"]), io)).toEqual({
			result: "picked",
			model: { provider: "google", id: "model-a", effort: "provider-default", price: NO_PRICE },
		});
		expect(asked.map(({ title }) => title)).toEqual(["google model", "Effort"]);
	});

	test("starts each menu on the saved choice", async () => {
		const saved: ModelSetting = { provider: "openai", id: "model-b", effort: "low", price: NO_PRICE };
		const { io, asked } = scriptedIo([1, 1, 3]);

		await pickModel(configWith(["anthropic", "openai"], saved), io);

		expect(asked.map(({ start }) => start)).toEqual([1, 1, 3]);
	});

	test("keeps the price when the model stays the same, and clears it when the model changes", async () => {
		const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: { input: 1, output: 2 } };
		const same = scriptedIo([0, 0]);
		const other = scriptedIo([1, 0]);

		expect(await pickModel(configWith(["openai"], saved), same.io)).toMatchObject({ model: { id: "model-a", price: { input: 1, output: 2 } } });
		expect(await pickModel(configWith(["openai"], saved), other.io)).toMatchObject({ model: { id: "model-b", price: NO_PRICE } });
	});

	describe("prices", () => {
		const LISTED: PricesResult = { ok: true, prices: { "model-a": { input_cost_per_token: 0.000003, output_cost_per_token: 0.000015 } } };

		test("shows each model's price and saves the picked one's", async () => {
			const { io, asked, warnings } = scriptedIo([0, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { id: "model-a", price: { input: 3, output: 15 } } });
			expect(asked[0].labels).toEqual(["Model A (model-a), $3 in, $15 out per million tokens", "model-b, no price"]);
			expect(warnings).toEqual([]);
		});

		test("keeps a price the user saved for the same model", async () => {
			const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: { input: 1, output: 2 } };
			const { io } = scriptedIo([0, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"], saved), io)).toMatchObject({ model: { price: { input: 1, output: 2 } } });
		});

		test("fills a blank saved price for the same model from the list", async () => {
			const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: NO_PRICE };
			const { io } = scriptedIo([0, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"], saved), io)).toMatchObject({ model: { price: { input: 3, output: 15 } } });
		});

		test("warns when the list has no price for the picked model", async () => {
			const { io, warnings } = scriptedIo([1, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { id: "model-b", price: NO_PRICE } });
			expect(warnings).toEqual(["The price list has no price for model-b, so the log shows no cost. Set model.price in the config file to see it"]);
		});

		test("warns once and picks with no price when the list fails", async () => {
			const { io, warnings } = scriptedIo([0, 0], MODELS, { ok: false, error: "The price list answered with 503" });

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { price: NO_PRICE } });
			expect(warnings).toEqual(["The price list answered with 503, so the models show no price"]);
		});
	});

	test("starts on the first row when the saved choice isn't listed", async () => {
		const saved: ModelSetting = { provider: "openai", id: "retired", effort: "", price: NO_PRICE };
		const { io, asked } = scriptedIo([0, 0]);

		await pickModel(configWith(["openai"], saved), io);

		expect(asked.map(({ start }) => start)).toEqual([0, 0]);
	});

	test("keeps the saved model when no provider has a key", async () => {
		const { io, asked } = scriptedIo([]);

		expect(await pickModel(configWith([]), io)).toEqual({ result: "kept", model: NO_MODEL });
		expect(asked).toEqual([]);
	});

	describe("after a failed list", () => {
		const REFUSED: ListResult = { ok: false, error: "openai answered the model list with 401: invalid x-api-key" };
		const SAVED: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: NO_PRICE };

		test("warns, then asks, starting on trying again", async () => {
			const { io, asked, warnings } = scriptedIo([2], REFUSED);

			await pickModel(configWith(["openai"], SAVED), io);

			expect(warnings).toEqual(["openai answered the model list with 401: invalid x-api-key"]);
			expect(asked).toEqual([{ title: "What now?", labels: ["Try again", "Use model-a (openai)", "Quit"], start: 0 }]);
		});

		test("uses the saved model only when the user picks it", async () => {
			const { io } = scriptedIo([1], REFUSED);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toEqual({ result: "kept", model: SAVED });
		});

		test("tries the list again", async () => {
			const { io, listed } = scriptedIo([0, 1, 0], [REFUSED, MODELS]);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toMatchObject({ result: "picked", model: { id: "model-b" } });
			expect(listed).toHaveLength(2);
		});

		test("picks another provider when several have a key", async () => {
			const { io, asked, listed } = scriptedIo([1, 0, 0, 0, 0], [REFUSED, MODELS]);

			expect(await pickModel(configWith(["anthropic", "openai"], SAVED), io)).toMatchObject({ result: "picked", model: { provider: "anthropic" } });
			expect(asked[1].labels[0]).toBe("Pick another provider");
			expect(listed).toEqual(["openai openai-key", "anthropic anthropic-key"]);
		});

		test("leaves out the saved model when it can't play", async () => {
			const { io, asked } = scriptedIo([1], REFUSED);

			expect(await pickModel(configWith(["openai"]), io)).toEqual({ result: "cancelled" });
			expect(asked[0].labels).toEqual(["Try again", "Quit"]);
		});

		test("quits on Ctrl+C", async () => {
			const { io } = scriptedIo([undefined], REFUSED);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toEqual({ result: "cancelled" });
		});

		test("names an empty list", async () => {
			const { io, warnings } = scriptedIo([1], { ok: true, models: [] });

			await pickModel(configWith(["google"]), io);

			expect(warnings).toEqual(["google listed no models"]);
		});
	});

	test.each([
		["provider", [undefined]],
		["model", [0, undefined]],
		["effort", [0, 0, undefined]],
	])("is cancelled at the %s menu", async (_menu, rows) => {
		const { io } = scriptedIo(rows);

		expect(await pickModel(configWith(["anthropic", "openai"]), io)).toEqual({ result: "cancelled" });
	});
});

describe("savedModelWarning", () => {
	test("says nothing when the saved model can play", () => {
		expect(savedModelWarning(configWith(["openai"], { provider: "openai", id: "model-a", effort: "", price: NO_PRICE }), "x.yaml")).toBeUndefined();
	});

	test("warns when no model is picked", () => {
		expect(savedModelWarning(configWith(["openai"], { provider: "openai", id: "", effort: "", price: NO_PRICE }), "x.yaml")).toMatch(/^No model is picked/);
		expect(savedModelWarning(configWith(["openai"]), "x.yaml")).toMatch(/^No model is picked/);
	});

	test("warns when the model's provider has no key", () => {
		expect(savedModelWarning(configWith(["anthropic"], { provider: "openai", id: "model-a", effort: "", price: NO_PRICE }), "x.yaml"))
			.toMatch(/^The picked model is from openai, which has no API key/);
	});
});
