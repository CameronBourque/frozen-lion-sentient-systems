// Tests for model/picker.ts, with scripted answers in place of the menus and
// a fake model list.

import { describe, expect, test } from "vitest";
import { type Config, DEFAULT_MCP_PORT, type ModelSetting, NO_MODEL } from "../../src/config.js";
import type { ListResult } from "../../src/model/list-models.js";
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
function scriptedIo(rows: (number | undefined)[], list: ListResult = MODELS) {
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

			return Promise.resolve(list);
		},
		warn: (text) => warnings.push(text),
	};

	return { io, asked, warnings, listed };
}

describe("pickModel", () => {
	test("asks for the provider, the model, and the effort", async () => {
		const { io, asked, listed } = scriptedIo([1, 1, 5]);

		expect(await pickModel(configWith(["anthropic", "openai"]), io)).toEqual({
			result: "picked",
			model: { provider: "openai", id: "model-b", effort: "high" },
		});
		expect(asked.map(({ title }) => title)).toEqual(["Provider", "openai model", "Effort"]);
		expect(asked[0].labels).toEqual(["anthropic", "openai"]);
		expect(asked[1].labels).toEqual(["Model A (model-a)", "model-b"]);
		expect(listed).toEqual(["openai openai-key"]);
	});

	test("skips the provider menu when only one provider has a key", async () => {
		const { io, asked } = scriptedIo([0, 0]);

		expect(await pickModel(configWith(["google"]), io)).toEqual({
			result: "picked",
			model: { provider: "google", id: "model-a", effort: "provider-default" },
		});
		expect(asked.map(({ title }) => title)).toEqual(["google model", "Effort"]);
	});

	test("starts each menu on the saved choice", async () => {
		const saved: ModelSetting = { provider: "openai", id: "model-b", effort: "low" };
		const { io, asked } = scriptedIo([1, 1, 3]);

		await pickModel(configWith(["anthropic", "openai"], saved), io);

		expect(asked.map(({ start }) => start)).toEqual([1, 1, 3]);
	});

	test("starts on the first row when the saved choice isn't listed", async () => {
		const saved: ModelSetting = { provider: "openai", id: "retired", effort: "" };
		const { io, asked } = scriptedIo([0, 0]);

		await pickModel(configWith(["openai"], saved), io);

		expect(asked.map(({ start }) => start)).toEqual([0, 0]);
	});

	test("keeps the saved model when no provider has a key", async () => {
		const { io, asked } = scriptedIo([]);

		expect(await pickModel(configWith([]), io)).toEqual({ result: "kept", model: NO_MODEL });
		expect(asked).toEqual([]);
	});

	test("warns and keeps the saved model when the list fails", async () => {
		const { io, warnings } = scriptedIo([], { ok: false, error: "openai answered the model list with 401 Unauthorized" });

		expect(await pickModel(configWith(["openai"]), io)).toEqual({ result: "kept", model: NO_MODEL });
		expect(warnings).toEqual(["openai answered the model list with 401 Unauthorized, so the bridge keeps the saved model"]);
	});

	test("warns and keeps the saved model when the list is empty", async () => {
		const { io, warnings } = scriptedIo([], { ok: true, models: [] });

		expect(await pickModel(configWith(["google"]), io)).toEqual({ result: "kept", model: NO_MODEL });
		expect(warnings).toEqual(["google listed no models, so the bridge keeps the saved model"]);
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
		expect(savedModelWarning(configWith(["openai"], { provider: "openai", id: "model-a", effort: "" }), "x.yaml")).toBeUndefined();
	});

	test("warns when no model is picked", () => {
		expect(savedModelWarning(configWith(["openai"], { provider: "openai", id: "", effort: "" }), "x.yaml")).toMatch(/^No model is picked/);
		expect(savedModelWarning(configWith(["openai"]), "x.yaml")).toMatch(/^No model is picked/);
	});

	test("warns when the model's provider has no key", () => {
		expect(savedModelWarning(configWith(["anthropic"], { provider: "openai", id: "model-a", effort: "" }), "x.yaml"))
			.toMatch(/^The picked model is from openai, which has no API key/);
	});
});
