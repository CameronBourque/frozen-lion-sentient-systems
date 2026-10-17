// Tests for writing-rules.mjs, the rule table, against the real docs/rules/writing.md.

import fs from "node:fs";
import path from "node:path";
import { describe, expect, test } from "vitest";
import { fixedRules, wordRules } from "./writing-rules.mjs";

describe("writing rule table", () => {
	const realWritingRules = fs.readFileSync(path.resolve(import.meta.dirname, "../../docs/rules/writing.md"), "utf8");
	const rules = [...fixedRules, ...wordRules(realWritingRules)];

	test("every pattern is global, so matchAll works", () => {
		for (const rule of rules) expect(rule.pattern.global, `${rule.rule} pattern needs the g flag`).toBeTruthy();
	});

	test("every example is caught by its own rule", () => {
		for (const rule of rules) {
			const matches = [...rule.example.matchAll(rule.pattern)].filter((m) => !rule.allow?.(rule.example, m));

			expect(matches.length > 0, `${rule.rule} does not catch its example "${rule.example}"`).toBeTruthy();
		}
	});

	test("a writing.md without the word lists fails", () => {
		expect(() => wordRules("No lists here.")).toThrow("has no");
	});

	test("the word lists load from the real writing.md", () => {
		expect("delve".match(rules.find((r) => r.rule === "inflated-word").pattern)).toBeTruthy();
		expect("scaffolding".match(rules.find((r) => r.rule === "metaphor-noun").pattern)).toBeTruthy();
	});
});
