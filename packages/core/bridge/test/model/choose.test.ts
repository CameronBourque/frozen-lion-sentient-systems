// Tests for model/choose.ts: the picker's choice is saved and logged, and
// without a terminal the saved model is checked, with a log file in a
// temporary folder.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { type Config, DEFAULT_JOURNAL_ENTRIES, DEFAULT_LIMITS, DEFAULT_MCP_PORT, type ModelSetting, NO_MODEL, NO_PRICE } from "../../src/config.js";
import { CONFIG_NAME, EXAMPLE_CONFIG, loadConfig } from "../../src/load-config.js";
import { Logger } from "../../src/log.js";
import { type ChooseIo, chooseModel } from "../../src/model/choose.js";
import type { CallModeSupport } from "../../src/model/providers/provider.js";
import { providersListing } from "./fake-providers.js";

const LISTING = providersListing(() => Promise.resolve({ ok: true, models: [{ id: "model-a", name: "model-a" }] }));
const FACTS: ChooseIo["facts"] = () => Promise.resolve({ ok: true, facts: { "openai/model-a": { supported_parameters: ["tools"] } } });

let folder: string;
let file: string;
let logger: Logger;

beforeEach(() => {
	folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
	file = path.join(folder, CONFIG_NAME);
	fs.writeFileSync(file, EXAMPLE_CONFIG);
	logger = new Logger("debug", "");
});

afterEach(() => {
	vi.restoreAllMocks();
	fs.rmSync(folder, { recursive: true, force: true });
});

function configWith(model: ModelSetting): Config {
	return { schemaVersion: 1, logLevel: "decisions", providers: { openai: { apiKey: "key" } }, model, mcpPort: DEFAULT_MCP_PORT, journalEntries: DEFAULT_JOURNAL_ENTRIES, limits: DEFAULT_LIMITS };
}

// Answers every menu with its first row.
const FIRST_ROWS: ChooseIo["ask"] = () => Promise.resolve(0);

describe("in a terminal", () => {
	test("uses, saves, and logs the picked model", async () => {
		const config = configWith(NO_MODEL);
		const info = vi.spyOn(logger, "info");

		expect(await chooseModel(config, file, logger, { ask: FIRST_ROWS, providers: LISTING, facts: FACTS })).toBe("api-key");

		const picked = { mode: "api-key", provider: "openai", id: "model-a", effort: "provider-default", price: NO_PRICE };

		expect(config.model).toEqual(picked);
		expect(loadConfig(file)).toMatchObject({ result: "loaded", config: { model: picked } });
		expect(info).toHaveBeenCalledWith("model_chosen", "Agents use openai model-a in API key mode, with provider-default effort", { mode: "api-key", provider: "openai", id: "model-a", effort: "provider-default" });
	});

	test("names the picked run mode in the log", async () => {
		const plan: CallModeSupport = {
			ready: () => ({ ok: true }),
			listModels: () => Promise.resolve({ ok: true, models: [{ id: "model-a", name: "model-a" }] }),
			model: () => ({ ok: false, error: "unused" }),
			runner: () => ({ ok: false, error: "unused" }),
		};
		const providers = LISTING.map((provider) => provider.name === "openai" ? { ...provider, modes: { ...provider.modes, subscription: plan } } : provider);
		// Subscription token, then the first row of each menu after it.
		const subscription: ChooseIo["ask"] = (title) => Promise.resolve(title === "Run mode" ? 1 : 0);
		const info = vi.spyOn(logger, "info");

		expect(await chooseModel(configWith(NO_MODEL), file, logger, { ask: subscription, providers, facts: FACTS })).toBe("subscription");

		expect(info).toHaveBeenCalledWith("model_chosen", "Agents use openai model-a in Subscription token mode, with provider-default effort", expect.objectContaining({ mode: "subscription" }));
	});

	test("logs a plan's model when no provider has an API key", async () => {
		const plan: CallModeSupport = {
			ready: () => ({ ok: true }),
			listModels: () => Promise.resolve({ ok: true, models: [{ id: "model-a", name: "model-a" }] }),
			model: () => ({ ok: false, error: "unused" }),
			runner: () => ({ ok: false, error: "unused" }),
		};
		const providers = LISTING.map((provider) => provider.name === "openai" ? { ...provider, modes: { ...provider.modes, subscription: plan } } : provider);
		const subscription: ChooseIo["ask"] = (title) => Promise.resolve(title === "Run mode" ? 1 : 0);
		const info = vi.spyOn(logger, "info");

		expect(await chooseModel({ ...configWith(NO_MODEL), providers: {} }, file, logger, { ask: subscription, providers, facts: FACTS })).toBe("subscription");
		expect(info).toHaveBeenCalledWith("model_chosen", expect.stringMatching(/in Subscription token mode/), expect.objectContaining({ mode: "subscription" }));
	});

	test("returns no mode when the user cancels", async () => {
		const cancel: ChooseIo["ask"] = () => Promise.resolve(undefined);

		expect(await chooseModel(configWith(NO_MODEL), file, logger, { ask: cancel, providers: LISTING, facts: FACTS })).toBeUndefined();
	});

	test("returns no mode when the user quits after the list fails", async () => {
		const warn = vi.spyOn(logger, "warn");
		const failing = providersListing(() => Promise.resolve({ ok: false, error: "offline" }));
		// API key, then Quit after the failed list.
		const quit: ChooseIo["ask"] = (title, labels) => Promise.resolve(title === "Run mode" ? 0 : labels.indexOf("Quit"));

		expect(await chooseModel(configWith(NO_MODEL), file, logger, { ask: quit, providers: failing, facts: FACTS })).toBeUndefined();
		expect(warn).toHaveBeenCalledWith("model_warning", "offline");
	});

	test("keeps and logs the saved model without saving it again", async () => {
		const info = vi.spyOn(logger, "info");
		const failing = providersListing(() => Promise.resolve({ ok: false, error: "offline" }));
		const saved: ModelSetting = { mode: "api-key", provider: "openai", id: "model-a", effort: "", price: NO_PRICE };
		// API key, then Use after the failed list.
		const use: ChooseIo["ask"] = (title, labels) => Promise.resolve(title === "Run mode" ? 0 : labels.findIndex((label) => label.startsWith("Use")));

		expect(await chooseModel(configWith(saved), file, logger, { ask: use, providers: failing, facts: FACTS })).toBe("api-key");
		expect(info).toHaveBeenCalledWith("model_chosen", expect.stringMatching(/^Agents use openai model-a in API key mode/), expect.objectContaining({ mode: "api-key" }));
		expect(fs.readFileSync(file, "utf8")).toBe(EXAMPLE_CONFIG);
	});

	test("warns when it can't save the choice", async () => {
		const warn = vi.spyOn(logger, "warn");

		await chooseModel(configWith(NO_MODEL), path.join(folder, "missing", CONFIG_NAME), logger, { ask: FIRST_ROWS, providers: LISTING, facts: FACTS });

		expect(warn).toHaveBeenCalledWith("model_warning", expect.stringMatching(/^Couldn't save the model/));
	});
});

describe("without a terminal", () => {
	test("logs the saved model, with the provider's default effort when it is blank", async () => {
		const info = vi.spyOn(logger, "info");
		const saved: ModelSetting = { mode: "api-key", provider: "openai", id: "model-a", effort: "", price: NO_PRICE };

		expect(await chooseModel(configWith(saved), file, logger, { providers: LISTING, facts: FACTS })).toBe("api-key");
		expect(info).toHaveBeenCalledWith("model_chosen", "Agents use openai model-a in API key mode, with the provider's default effort", { mode: "api-key", provider: "openai", id: "model-a", effort: "" });
	});

	test("logs nothing about the model when no provider has a key", async () => {
		const info = vi.spyOn(logger, "info");
		const warn = vi.spyOn(logger, "warn");
		const config = { ...configWith({ mode: "api-key", provider: "openai", id: "model-a", effort: "", price: NO_PRICE }), providers: {} };

		expect(await chooseModel(config, file, logger, { providers: LISTING, facts: FACTS })).toBe("api-key");
		expect(info).not.toHaveBeenCalled();
		expect(warn).not.toHaveBeenCalled();
	});

	test("warns when no model is saved, and doesn't write the file", async () => {
		const warn = vi.spyOn(logger, "warn");

		await chooseModel(configWith(NO_MODEL), file, logger, { providers: LISTING, facts: FACTS });

		expect(warn).toHaveBeenCalledWith("model_warning", expect.stringMatching(/^No model is picked/));
		expect(fs.readFileSync(file, "utf8")).toBe(EXAMPLE_CONFIG);
	});
});
