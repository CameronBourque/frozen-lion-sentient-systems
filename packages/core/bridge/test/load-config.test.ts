// Tests for load-config.ts.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { parseConfig } from "../src/config.js";
import { CONFIG_NAME, EXAMPLE_CONFIG, findConfigPath, keyWarning, loadConfig, startConfig } from "../src/load-config.js";

const EXECUTABLE = path.resolve("/games/bridge/sentient-systems-bridge.exe");
const CWD = path.resolve("/work/bridge");

describe("findConfigPath", () => {
	test("reads the path in --config, from the current folder", () => {
		const found = findConfigPath({ args: ["--config", "../tmp/my.yaml"], cwd: CWD, execPath: EXECUTABLE, isExecutable: true });

		expect(found).toEqual({ ok: true, path: path.resolve("/work/tmp/my.yaml") });
	});

	test("reads --config in its = form", () => {
		const found = findConfigPath({ args: ["--config=my.yaml"], cwd: CWD, execPath: EXECUTABLE, isExecutable: false });

		expect(found).toEqual({ ok: true, path: path.join(CWD, "my.yaml") });
	});

	test("looks next to the executable", () => {
		const found = findConfigPath({ args: [], cwd: CWD, execPath: EXECUTABLE, isExecutable: true });

		expect(found).toEqual({ ok: true, path: path.join(path.dirname(EXECUTABLE), CONFIG_NAME) });
	});

	test("looks in the current folder when tsx runs the bridge", () => {
		const found = findConfigPath({ args: [], cwd: CWD, execPath: EXECUTABLE, isExecutable: false });

		expect(found).toEqual({ ok: true, path: path.join(CWD, CONFIG_NAME) });
	});

	test("fails on an unknown option", () => {
		const found = findConfigPath({ args: ["--confg", "my.yaml"], cwd: CWD, execPath: EXECUTABLE, isExecutable: true });

		expect(found).toMatchObject({ ok: false, error: expect.stringContaining("--confg") as unknown });
	});

	test("fails on --config with no path", () => {
		const found = findConfigPath({ args: ["--config"], cwd: CWD, execPath: EXECUTABLE, isExecutable: true });

		expect(found).toMatchObject({ ok: false, error: expect.stringContaining("--config") as unknown });
	});
});

describe("loadConfig", () => {
	let folder: string;

	beforeEach(() => {
		folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
	});

	afterEach(() => {
		fs.rmSync(folder, { recursive: true, force: true });
	});

	test("reads a valid file", () => {
		const file = path.join(folder, CONFIG_NAME);

		fs.writeFileSync(file, "schemaVersion: 1\nlogLevel: full");

		expect(loadConfig(file)).toEqual({ result: "loaded", config: { schemaVersion: 1, logLevel: "full", providers: {} } });
	});

	test("returns the errors of a bad file", () => {
		const file = path.join(folder, CONFIG_NAME);

		fs.writeFileSync(file, "schemaVersion: 1\nlogLevel: loud");

		expect(loadConfig(file)).toMatchObject({ result: "invalid", errors: [expect.stringMatching(/^logLevel: /) as unknown] });
	});

	test("writes the example for a missing file, in a new folder", () => {
		const file = path.join(folder, "tmp", CONFIG_NAME);

		expect(loadConfig(file)).toEqual({ result: "created" });
		expect(fs.readFileSync(file, "utf8")).toBe(EXAMPLE_CONFIG);
	});
});

describe("EXAMPLE_CONFIG", () => {
	test("is a valid config with every provider and no keys", () => {
		expect(parseConfig(EXAMPLE_CONFIG)).toEqual({
			ok: true,
			config: { schemaVersion: 1, logLevel: "decisions", providers: { anthropic: { apiKey: "" }, openai: { apiKey: "" } } },
		});
	});
});

describe("keyWarning", () => {
	test("warns when no provider has a key, and names the file", () => {
		const config = { schemaVersion: 1 as const, logLevel: "decisions" as const, providers: { anthropic: { apiKey: "" } } };

		expect(keyWarning(config, "C:/bridge/sentient-systems.yaml")).toContain("C:/bridge/sentient-systems.yaml");
	});

	test("warns when there are no providers", () => {
		expect(keyWarning({ schemaVersion: 1, logLevel: "decisions", providers: {} }, "x.yaml")).toBeDefined();
	});

	test("lets a config with one key through", () => {
		const config = { schemaVersion: 1 as const, logLevel: "decisions" as const, providers: { anthropic: { apiKey: "" }, openai: { apiKey: "key" } } };

		expect(keyWarning(config, "x.yaml")).toBeUndefined();
	});
});

describe("startConfig", () => {
	let folder: string;

	// Runs startConfig the way tsx runs the bridge, in the test's folder.
	function start(args: string[] = []): ReturnType<typeof startConfig> {
		return startConfig({ args, cwd: folder, execPath: EXECUTABLE, isExecutable: false });
	}

	beforeEach(() => {
		folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
	});

	afterEach(() => {
		fs.rmSync(folder, { recursive: true, force: true });
	});

	test("returns the config, its path, and the missing key warning", () => {
		fs.writeFileSync(path.join(folder, CONFIG_NAME), "schemaVersion: 1");

		expect(start()).toEqual({
			ok: true,
			config: { schemaVersion: 1, logLevel: "decisions", providers: {} },
			path: path.join(folder, CONFIG_NAME),
			warnings: [expect.stringContaining("No provider has an API key") as unknown],
		});
	});

	test("has no warnings for a config with a key", () => {
		fs.writeFileSync(path.join(folder, CONFIG_NAME), "schemaVersion: 1\nproviders:\n  anthropic:\n    apiKey: key");

		expect(start()).toMatchObject({ ok: true, warnings: [] });
	});

	test("says how to fill in a new example, and names its path", () => {
		expect(start()).toEqual({ ok: false, error: expect.stringContaining(path.join(folder, CONFIG_NAME)) as unknown });
	});

	test("lists each error in a bad file", () => {
		fs.writeFileSync(path.join(folder, CONFIG_NAME), "schemaVersion: 1\nlogLevel: loud\nloglevel: full");

		expect(start()).toEqual({ ok: false, error: expect.stringMatching(/has errors:\nlogLevel: .*\nloglevel: Unknown field$/) as unknown });
	});

	test("names the only option after an unknown one", () => {
		expect(start(["--confg", "x"])).toEqual({ ok: false, error: expect.stringContaining("The only option is --config <path>") as unknown });
	});
});
