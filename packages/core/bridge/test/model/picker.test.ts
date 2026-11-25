// Tests for model/picker.ts, with scripted answers in place of the menus and
// a fake model list. The Run mode menu has its own script, which picks API key
// once it runs out.

import { describe, expect, test } from "vitest";
import { type Config, DEFAULT_JOURNAL_ENTRIES, DEFAULT_MCP_PORT, type ModelSetting, NO_MODEL, NO_PRICE } from "../../src/config.js";
import type { ListResult } from "../../src/model/list-models.js";
import type { FactsResult } from "../../src/model/model-facts.js";
import { type PickerIo, pickModel, savedModelWarning } from "../../src/model/picker.js";
import type { ModeSupport } from "../../src/model/providers/provider.js";
import { providersListing, realProviders } from "./fake-providers.js";

const MODELS: ListResult = {
	ok: true,
	models: [{ id: "model-a", name: "Model A" }, { id: "model-b", name: "model-b" }],
};

// Both models call tools and reason at every provider, with every effort
// level, and neither has a price.
const TOOLS = { supported_parameters: ["tools"], reasoning: {} };
const TOOL_FACTS: FactsResult = {
	ok: true,
	facts: Object.fromEntries(["anthropic", "openai", "google"].flatMap((provider) => [[`${provider}/model-a`, TOOLS], [`${provider}/model-b`, TOOLS]])),
};

function configWith(keys: string[], model: ModelSetting = NO_MODEL): Config {
	return {
		schemaVersion: 1,
		logLevel: "decisions",
		providers: Object.fromEntries(keys.map((provider) => [provider, { apiKey: `${provider}-key` }])),
		model,
		mcpPort: DEFAULT_MCP_PORT,
		journalEntries: DEFAULT_JOURNAL_ENTRIES,
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
function scriptedIo(rows: (number | undefined)[], list: ListResult | ListResult[] = MODELS, facts: FactsResult = TOOL_FACTS, modeRows: (number | undefined)[] = []) {
	const lists = Array.isArray(list) ? [...list] : [list];
	const asked: Asked[] = [];
	const modesAsked: Asked[] = [];
	const warnings: string[] = [];
	const listed: string[] = [];
	const io: PickerIo = {
		ask: (title, labels, start) => {
			if (title === "Run mode") {
				modesAsked.push({ title, labels, start });

				return Promise.resolve(modeRows.length > 0 ? modeRows.shift() : 0);
			}

			asked.push({ title, labels, start });

			return Promise.resolve(rows.shift());
		},
		providers: providersListing((provider, config) => {
			listed.push(`${provider} ${config.providers[provider]?.apiKey}`);

			return Promise.resolve(lists.length > 1 ? lists.shift() as ListResult : lists[0]);
		}),
		facts: () => Promise.resolve(facts),
		warn: (text) => warnings.push(text),
	};

	return { io, asked, modesAsked, warnings, listed };
}

describe("pickModel", () => {
	test("asks for the provider, the model, and the effort", async () => {
		const { io, asked, listed } = scriptedIo([1, 1, 5]);

		expect(await pickModel(configWith(["anthropic", "openai"]), io)).toEqual({
			result: "picked",
			mode: "api-key",
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
			mode: "api-key",
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
		const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: { input: 1, output: 2, cacheRead: "", cacheWrite: "" } };
		const same = scriptedIo([0, 0]);
		const other = scriptedIo([1, 0]);

		expect(await pickModel(configWith(["openai"], saved), same.io)).toMatchObject({ model: { id: "model-a", price: { input: 1, output: 2 } } });
		expect(await pickModel(configWith(["openai"], saved), other.io)).toMatchObject({ model: { id: "model-b", price: NO_PRICE } });
	});

	describe("prices", () => {
		const LISTED: FactsResult = {
			ok: true,
			facts: { "openai/model-a": { ...TOOLS, pricing: { prompt: "0.000003", completion: "0.000015", input_cache_read: "0.0000003" } }, "openai/model-b": TOOLS },
		};

		test("shows each model's price and saves the picked one's", async () => {
			const { io, asked, warnings } = scriptedIo([0, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { id: "model-a", price: { input: 3, output: 15 } } });
			expect(asked[0].labels).toEqual(["Model A (model-a), $3 in, $15 out per million tokens", "model-b, no price"]);
			expect(warnings).toEqual([]);
		});

		test("keeps each price the user saved for the same model, and fills the blank ones", async () => {
			const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: { input: 1, output: 2, cacheRead: "", cacheWrite: "" } };
			const { io } = scriptedIo([0, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"], saved), io)).toMatchObject({ model: { price: { input: 1, output: 2, cacheRead: 0.3, cacheWrite: "" } } });
		});

		test("fills a blank saved price for the same model from the list", async () => {
			const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: NO_PRICE };
			const { io } = scriptedIo([0, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"], saved), io)).toMatchObject({ model: { price: { input: 3, output: 15 } } });
		});

		test("warns when the list has no price for the picked model", async () => {
			const { io, warnings } = scriptedIo([1, 0], MODELS, LISTED);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { id: "model-b", price: NO_PRICE } });
			expect(warnings).toEqual(["OpenRouter lists no price for model-b, so the log shows no cost. Set model.price in the config file to see it"]);
		});

		test("warns once and picks with no price when the list fails", async () => {
			const { io, warnings } = scriptedIo([0, 0], MODELS, { ok: false, error: "OpenRouter's model list answered with 503" });

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { price: NO_PRICE } });
			expect(warnings).toEqual(["OpenRouter's model list answered with 503, so the menu lists every model openai has, with no prices"]);
		});
	});

	test("starts on the first row when the saved choice isn't listed", async () => {
		const saved: ModelSetting = { provider: "openai", id: "retired", effort: "", price: NO_PRICE };
		const { io, asked } = scriptedIo([0, 0]);

		await pickModel(configWith(["openai"], saved), io);

		expect(asked.map(({ start }) => start)).toEqual([0, 0]);
	});

	describe("run mode", () => {
		test("lists every mode and Quit, starting on API key", async () => {
			const { io, modesAsked } = scriptedIo([0, 0]);

			await pickModel(configWith(["openai"]), io);

			expect(modesAsked).toEqual([{
				title: "Run mode",
				labels: ["API key", "Subscription token (not available yet)", "Agent SDK (not available yet)", "CLI (not available yet)", "Quit"],
				start: 0,
			}]);
		});

		test("warns and asks again when the mode isn't available yet", async () => {
			const { io, modesAsked, warnings } = scriptedIo([0, 0], MODELS, TOOL_FACTS, [2, 0]);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ result: "picked", mode: "api-key" });
			expect(modesAsked).toHaveLength(2);
			expect(warnings[0]).toBe("Agent SDK isn't available yet, so pick another run mode");
		});

		test.each([
			["Quit", 4],
			["Ctrl+C", undefined],
		])("is cancelled by %s", async (_key, row) => {
			const { io, asked } = scriptedIo([], MODELS, TOOL_FACTS, [row]);

			expect(await pickModel(configWith(["openai"]), io)).toEqual({ result: "cancelled" });
			expect(asked).toEqual([]);
		});

		test("warns with each provider's reason and asks again when none can play", async () => {
			const { io, asked, modesAsked, warnings } = scriptedIo([], MODELS, TOOL_FACTS, [0, 4]);

			expect(await pickModel(configWith([]), io)).toEqual({ result: "cancelled" });
			expect(asked).toEqual([]);
			expect(modesAsked).toHaveLength(2);
			expect(warnings).toEqual([expect.stringMatching(/^No provider can play in API key, so pick another run mode or Quit\. No API key for anthropic\..*No API key for openai\..*No API key for google\./) as unknown]);
		});

		test("offers only the providers that have the mode", async () => {
			const plan: ModeSupport = {
				ready: () => ({ ok: true }),
				listModels: () => Promise.resolve(MODELS),
				model: () => ({ ok: false, error: "unused" }),
			};
			const { io, asked, modesAsked } = scriptedIo([0, 0], MODELS, TOOL_FACTS, [1]);

			io.providers = io.providers.map((provider) => provider.name === "openai" ? { ...provider, modes: { ...provider.modes, subscription: plan } } : provider);

			expect(await pickModel(configWith(["anthropic", "openai"]), io)).toMatchObject({ result: "picked", mode: "subscription", model: { provider: "openai" } });
			expect(modesAsked[0].labels[1]).toBe("Subscription token");
			expect(asked.map(({ title }) => title)).toEqual(["openai model", "Effort"]);
		});
	});

	describe("effort", () => {
		test("offers the model's levels, and names the default", async () => {
			const reasoning = { supported_efforts: ["high", "low"], default_effort: "high" };
			const facts: FactsResult = { ok: true, facts: { "openai/model-a": { ...TOOLS, reasoning } } };
			const { io, asked } = scriptedIo([0, 2], MODELS, facts);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { effort: "high" } });
			expect(asked[1].labels).toEqual(["provider-default (high)", "low", "high"]);
		});

		test("starts on the first level when the saved one isn't offered", async () => {
			const saved: ModelSetting = { provider: "openai", id: "model-a", effort: "minimal", price: NO_PRICE };
			const facts: FactsResult = { ok: true, facts: { "openai/model-a": { ...TOOLS, reasoning: { supported_efforts: ["low"] } } } };
			const { io, asked } = scriptedIo([0, 0], MODELS, facts);

			expect(await pickModel(configWith(["openai"], saved), io)).toMatchObject({ model: { effort: "provider-default" } });
			expect(asked[1].start).toBe(0);
		});
	});

	describe("tool support", () => {
		test("offers only the models that call tools", async () => {
			const facts: FactsResult = { ok: true, facts: { "openai/model-b": TOOLS, "openai/model-a": { supported_parameters: [] } } };
			const { io, asked } = scriptedIo([0, 0], MODELS, facts);

			expect(await pickModel(configWith(["openai"]), io)).toMatchObject({ model: { id: "model-b" } });
			expect(asked[0].labels).toEqual(["model-b, no price"]);
		});

		test("offers every model when OpenRouter's list can't be read", async () => {
			const { io, asked } = scriptedIo([0, 0], MODELS, { ok: false, error: "offline" });

			await pickModel(configWith(["openai"]), io);

			expect(asked[0].labels).toHaveLength(2);
		});

		test("asks what to do when no model calls tools", async () => {
			const { io, asked, warnings } = scriptedIo([2], MODELS, { ok: true, facts: {} });

			expect(await pickModel(configWith(["openai"]), io)).toEqual({ result: "cancelled" });
			expect(warnings).toEqual(["openai listed no models that call tools"]);
			expect(asked[0].title).toBe("What now?");
		});
	});

	describe("after a failed list", () => {
		const REFUSED: ListResult = { ok: false, error: "openai answered the model list with 401: invalid x-api-key" };
		const SAVED: ModelSetting = { provider: "openai", id: "model-a", effort: "", price: NO_PRICE };

		test("warns, then asks, starting on trying again", async () => {
			const { io, asked, warnings } = scriptedIo([3], REFUSED);

			await pickModel(configWith(["openai"], SAVED), io);

			expect(warnings).toEqual(["openai answered the model list with 401: invalid x-api-key"]);
			expect(asked).toEqual([{ title: "What now?", labels: ["Try again", "Pick another run mode", "Use model-a (openai)", "Quit"], start: 0 }]);
		});

		test("uses the saved model only when the user picks it", async () => {
			const { io } = scriptedIo([2], REFUSED);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toEqual({ result: "kept", mode: "api-key", model: SAVED });
		});

		test("tries the list again", async () => {
			const { io, listed } = scriptedIo([0, 1, 0], [REFUSED, MODELS]);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toMatchObject({ result: "picked", model: { id: "model-b" } });
			expect(listed).toHaveLength(2);
		});

		test("picks another provider in the same run mode when several have a key", async () => {
			const { io, asked, modesAsked, listed } = scriptedIo([1, 0, 0, 0, 0], [REFUSED, MODELS]);

			expect(await pickModel(configWith(["anthropic", "openai"], SAVED), io)).toMatchObject({ result: "picked", model: { provider: "anthropic" } });
			expect(asked[1].labels[0]).toBe("Pick another provider");
			expect(modesAsked).toHaveLength(1);
			expect(listed).toEqual(["openai openai-key", "anthropic anthropic-key"]);
		});

		test("goes back to the Run mode menu", async () => {
			const { io, modesAsked, listed } = scriptedIo([1, 0, 0], [REFUSED, MODELS]);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toMatchObject({ result: "picked", model: { id: "model-a" } });
			expect(modesAsked).toHaveLength(2);
			expect(listed).toHaveLength(2);
		});

		test("leaves out the saved model when it can't play", async () => {
			const { io, asked } = scriptedIo([2], REFUSED);

			expect(await pickModel(configWith(["openai"]), io)).toEqual({ result: "cancelled" });
			expect(asked[0].labels).toEqual(["Try again", "Pick another run mode", "Quit"]);
		});

		test("quits on Ctrl+C", async () => {
			const { io } = scriptedIo([undefined], REFUSED);

			expect(await pickModel(configWith(["openai"], SAVED), io)).toEqual({ result: "cancelled" });
		});

		test("names an empty list", async () => {
			const { io, warnings } = scriptedIo([2], { ok: true, models: [] });

			await pickModel(configWith(["google"]), io);

			expect(warnings).toEqual(["google listed no models that call tools"]);
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
		expect(savedModelWarning(configWith(["openai"], { provider: "openai", id: "model-a", effort: "", price: NO_PRICE }), "x.yaml", realProviders())).toBeUndefined();
	});

	test("warns when no model is picked", () => {
		expect(savedModelWarning(configWith(["openai"], { provider: "openai", id: "", effort: "", price: NO_PRICE }), "x.yaml", realProviders())).toMatch(/^No model is picked/);
		expect(savedModelWarning(configWith(["openai"]), "x.yaml", realProviders())).toMatch(/^No model is picked/);
	});

	test("warns when the model's provider has no key", () => {
		expect(savedModelWarning(configWith(["anthropic"], { provider: "openai", id: "model-a", effort: "", price: NO_PRICE }), "x.yaml", realProviders()))
			.toMatch(/^The picked model is from openai, which has no API key/);
	});
});
