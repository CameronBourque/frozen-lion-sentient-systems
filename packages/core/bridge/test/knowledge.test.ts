// Tests for knowledge.ts.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { knowledgeFromAssets, knowledgeFromFolder } from "../src/knowledge.js";

describe("knowledgeFromFolder", () => {
	let folder: string;

	beforeEach(() => {
		folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
	});

	afterEach(() => {
		fs.rmSync(folder, { recursive: true, force: true });
	});

	test("reads each file under the folder, keyed by its path with forward slashes", () => {
		fs.mkdirSync(path.join(folder, "personalities"));
		fs.writeFileSync(path.join(folder, "personalities", "calm.md"), "# Calm\n");
		fs.writeFileSync(path.join(folder, "top.md"), "# Top\n");

		expect(knowledgeFromFolder(folder)).toEqual(new Map([["personalities/calm.md", "# Calm\n"], ["top.md", "# Top\n"]]));
	});

	test("skips folders with no files", () => {
		fs.mkdirSync(path.join(folder, "empty"));

		expect(knowledgeFromFolder(folder).size).toBe(0);
	});

	test("reads the files that ship with the bridge", () => {
		const knowledge = knowledgeFromFolder(path.join(import.meta.dirname, "..", "knowledge"));

		expect(knowledge.get("personalities/neutral.md")).toMatch(/^# Neutral/);
		expect(knowledge.get("sweat/balanced.md")).toMatch(/^# Balanced/);
	});
});

describe("knowledgeFromAssets", () => {
	test("reads the assets in the knowledge folder, keyed by their path in it", () => {
		const assets = new Map([["knowledge/sweat/calm.md", "# Calm\n"], ["icon.png", "png"]]);

		const knowledge = knowledgeFromAssets([...assets.keys()], (key) => assets.get(key) ?? "");

		expect(knowledge).toEqual(new Map([["sweat/calm.md", "# Calm\n"]]));
	});

	test("skips a key that only starts with the folder's name", () => {
		expect(knowledgeFromAssets(["knowledge-old/a.md"], () => "text").size).toBe(0);
	});
});
