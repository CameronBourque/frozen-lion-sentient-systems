// Tests for writing.mjs, check 4. They run each rule through checkWriting.

import { describe, expect, test } from "vitest";
import { buildRepo } from "../src/parse.mjs";
import { lines } from "./helpers.mjs";
import { checkWriting } from "../src/writing.mjs";

describe("writing", () => {
	const writingRules = lines(
		"**Inflated words.** Robust, seamless, enhance. Use the plain word.",
		"**Abstract metaphor nouns.** Substrate, north star. Use the concrete word.",
	);

	// Returns the rule names that checkWriting reports for one doc.
	const rulesHit = (text) =>
		checkWriting(buildRepo({ "docs/rules/writing.md": writingRules, "docs/a.md": text })).map((p) => p.rule);

	test("dashes", () => {
		expect(rulesHit("One — two.\n")).toEqual(["dash"]);
		expect(rulesHit("Pages 1–2.\n")).toEqual(["dash"]);
		expect(rulesHit("The Indonesia–Khmer border.\n")).toEqual([]);
	});

	test("quotes, arrows, and emojis", () => {
		expect(rulesHit("A “quote”.\n")).toEqual(["quotes", "quotes"]);
		expect(rulesHit("Parse → exit, or parse -> exit.\n")).toEqual(["arrow", "arrow"]);
		expect(rulesHit("Text <!-- a comment --> here.\n")).toEqual([]);
		expect(rulesHit("Done 🎉.\n")).toEqual(["emoji"]);
	});

	test("Phase N mid-sentence", () => {
		expect(rulesHit("We start Phase 0 now.\n")).toEqual(["phase-case"]);
		expect(rulesHit("Phase 0 starts. Phase 1 follows.\n")).toEqual([]);
		expect(rulesHit("| Phase 1 | Done |\n- Phase 2\n[Phase 3](a.md) is later.\n")).toEqual([]);
	});

	test("dates", () => {
		expect(rulesHit("On Oct 14, 2026.\n")).toEqual(["date"]);
		expect(rulesHit("On 14 October 2026.\n")).toEqual(["date"]);
		expect(rulesHit("In October 2026.\n")).toEqual(["date"]);
		expect(rulesHit("On 10/14/2026.\n")).toEqual(["date"]);
		expect(rulesHit("On 2026-10-14. You may 2 things.\n")).toEqual([]);
	});

	test("GitHub links must be pinned", () => {
		expect(rulesHit("[x](https://github.com/o/r/blob/main/a.md)\n")).toEqual(["pinned-source"]);
		expect(rulesHit("[x](https://github.com/o/r/tree/dd20190/src)\n")).toEqual([]);
		expect(rulesHit("[x](https://github.com/o/r/blob/v1.2.0/a.md)\n")).toEqual([]);
	});

	test("inflated words and metaphor nouns, with their forms", () => {
		expect(rulesHit("A robust design that enhances and is enhancing.\n")).toEqual(["inflated-word", "inflated-word", "inflated-word"]);
		expect(rulesHit("Our north star and our substrates.\n")).toEqual(["metaphor-noun", "metaphor-noun"]);
		expect(rulesHit("Use `robust` here. [a](https://example.com/robust).\n")).toEqual([]);
	});

	test("procedure words only in numbered steps", () => {
		expect(rulesHit("1. Simply run it, please.\n")).toEqual(["procedure-word", "procedure-word"]);
		expect(rulesHit("1. Release-please opens a PR.\n")).toEqual([]);
		expect(rulesHit("It is easy.\n")).toEqual([]);
	});

	test("Title Case headings", () => {
		const body = "The tuner client uses a protocol.\n";

		expect(rulesHit(`# Tuner Client Protocol\n${body}`)).toEqual(["heading-case"]);
		expect(rulesHit(`# Tuner client protocol\n${body}`)).toEqual([]);
		expect(rulesHit(`# Phase 0: Prove the client\n${body}`)).toEqual([]);
		// "Lua" and "FireTuner" never appear in lowercase, so they are proper nouns.
		expect(rulesHit(`# Lua and FireTuner\n${body}`)).toEqual([]);
	});

	test("fails without writing.md, because the word lists come from it", () => {
		expect(() => checkWriting(buildRepo({ "docs/a.md": "# A\n" }))).toThrow("docs/rules/writing.md is missing");
	});

	test("writing.md itself is skipped", () => {
		expect(checkWriting(buildRepo({ "docs/rules/writing.md": `${writingRules}Robust — “x” →\n` }))).toEqual([]);
	});
});
