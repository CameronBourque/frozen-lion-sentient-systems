// Tests for the docs check. Run: node --test scripts/check-docs/checks.test.mjs

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { describe, test } from "node:test";
import { buildRepo, parse, resolveLink, slug } from "./parse.mjs";
import { checkLinks } from "./links.mjs";
import { checkIndexes } from "./indexes.mjs";
import { checkSections } from "./sections.mjs";
import { checkWriting } from "./writing.mjs";
import { checkLength, MAX_LINES } from "./length.mjs";
import { fixedRules, wordRules } from "./writing-rules.mjs";

const lines = (...rows) => rows.join("\n") + "\n";
const messages = (problems) => problems.map((p) => `${p.file}:${p.line}: ${p.rule}: ${p.message}`);

describe("parse", () => {
	test("slug follows GitHub's anchor rules", () => {
		assert.equal(slug("Step 2: Turn on the tuner"), "step-2-turn-on-the-tuner");
		assert.equal(slug("Game properties (for checkpoint IDs)"), "game-properties-for-checkpoint-ids");
		assert.equal(slug("The `EnableTuner` setting"), "the-enabletuner-setting");
		assert.equal(slug("See [design](design.md)"), "see-design");
	});

	test("repeated headings get numbered anchors", () => {
		const doc = parse("a.md", lines("# A", "## Notes", "## Notes"));

		assert.deepEqual([...doc.anchors], ["a", "notes", "notes-1"]);
	});

	test("code blocks and inline code are blanked, and line numbers stay", () => {
		const doc = parse("a.md", lines("# A", "```", "## Not a heading", "```", "~~~", "text", "~~~", "Use `code` here."));

		assert.deepEqual(doc.headings.map((h) => h.text), ["A"]);
		assert.equal(doc.text[2], "");
		assert.equal(doc.text[7], "Use        here.");
	});

	test("resolveLink handles relative, anchor-only, root, folder, and external links", () => {
		assert.deepEqual(resolveLink("docs/a/b.md", "../c.md#x"), { path: "docs/c.md", anchor: "x" });
		assert.deepEqual(resolveLink("docs/a.md", "#x"), { path: "docs/a.md", anchor: "x" });
		assert.deepEqual(resolveLink("docs/a.md", "/README.md"), { path: "README.md", anchor: undefined });
		assert.deepEqual(resolveLink("docs/a.md", "design/"), { path: "docs/design", anchor: undefined });
		assert.deepEqual(resolveLink("docs/a.md", "../"), { path: "", anchor: undefined });
		assert.equal(resolveLink("docs/a.md", "https://example.com"), null);
		assert.equal(resolveLink("docs/a.md", "mailto:a@example.com"), null);
	});
});

describe("links", () => {
	const repo = buildRepo({
		"docs/a.md": lines(
			"# A",
			"[ok](b.md) [missing](nope.md) [anchor](b.md#part-one) [bad anchor](b.md#nope)",
			"[folder](sub/) [folder anchor](sub/#sub) [web](https://example.com) [self](#a)",
			"`[in code](nope.md)`",
		),
		"docs/b.md": lines("# B", "## Part one"),
		"docs/sub/README.md": lines("# Sub"),
	});

	test("reports missing files and anchors only", () => {
		assert.deepEqual(messages(checkLinks(repo)), [
			"docs/a.md:2: link: nope.md does not exist",
			"docs/a.md:2: link: #nope is not a heading in docs/b.md",
		]);
	});
});

describe("indexes", () => {
	test("passes when every file and subfolder is linked", () => {
		const repo = buildRepo({
			"docs/README.md": lines("# Docs", "[a](a.md) [sub](sub/README.md)"),
			"docs/a.md": "# A\n",
			"docs/sub/README.md": lines("# Sub", "[b](b.md)"),
			"docs/sub/b.md": "# B\n",
		});

		assert.deepEqual(checkIndexes(repo), []);
	});

	test("reports a missing README and unlinked children", () => {
		const repo = buildRepo({
			"docs/README.md": "# Docs\n",
			"docs/a.md": "# A\n",
			"docs/sub/b.md": "# B\n",
			"packages/x/notes.md": "# Not under docs\n",
		});

		assert.deepEqual(messages(checkIndexes(repo)), [
			"docs/README.md:1: index: a.md is not linked from this index",
			"docs/README.md:1: index: sub/ is not linked from this index",
			"docs/sub:1: index: folder has no README.md",
		]);
	});
});

describe("sections", () => {
	const finding = lines("# F", "Status: open.", "## Questions", "## What we know now", "## Method", "## Results", "Date checked: not yet.");

	test("a complete finding passes", () => {
		assert.deepEqual(checkSections(buildRepo({ "docs/findings/f.md": finding })), []);
	});

	test("a finding lists each missing part", () => {
		assert.deepEqual(messages(checkSections(buildRepo({ "docs/findings/f.md": lines("# F", "## Questions") }))), [
			"docs/findings/f.md:1: sections: finding is missing ## What we know now",
			"docs/findings/f.md:1: sections: finding is missing ## Method",
			"docs/findings/f.md:1: sections: finding is missing ## Results",
			"docs/findings/f.md:1: sections: finding is missing a Status: line",
			"docs/findings/f.md:1: sections: finding is missing a Date checked: line",
		]);
	});

	test("a roadmap step needs its phase link and sections", () => {
		const step = lines("# Step 1", "Part of [phase 0](README.md).", "## Tasks", "## Done when", "## Record");

		assert.deepEqual(checkSections(buildRepo({ "docs/roadmap/phase-0/01-x.md": step })), []);
		assert.equal(checkSections(buildRepo({ "docs/roadmap/phase-0/01-x.md": "# Step 1\n" })).length, 4);
	});

	test("a design file must end with a Decision | Reason table", () => {
		const good = lines("# D", "## Decisions", "", "| Decision | Reason |", "| --- | --- |");
		const wrongHeader = lines("# D", "## Decisions", "", "| Choice | Why |");
		const wrongEnd = lines("# D", "## Decisions", "## Notes");

		assert.deepEqual(checkSections(buildRepo({ "docs/design/d.md": good })), []);
		assert.deepEqual(messages(checkSections(buildRepo({ "docs/design/d.md": wrongHeader }))), [
			"docs/design/d.md:2: sections: ## Decisions table header must be Decision | Reason",
		]);
		assert.deepEqual(messages(checkSections(buildRepo({ "docs/design/d.md": wrongEnd }))), [
			"docs/design/d.md:3: sections: design file must end with ## Decisions",
		]);
	});

	test("READMEs are exempt", () => {
		assert.deepEqual(checkSections(buildRepo({ "docs/design/README.md": "# Design\n", "docs/findings/README.md": "# Findings\n" })), []);
	});
});

describe("writing", () => {
	const writingRules = lines(
		"**Inflated words.** Robust, seamless, enhance. Use the plain word.",
		"**Abstract metaphor nouns.** Substrate, north star. Use the concrete word.",
	);
	// Returns the rule names that checkWriting reports for one doc.
	const rulesHit = (text) =>
		checkWriting(buildRepo({ "docs/rules/writing.md": writingRules, "docs/a.md": text })).map((p) => p.rule);

	test("dashes", () => {
		assert.deepEqual(rulesHit("One — two.\n"), ["dash"]);
		assert.deepEqual(rulesHit("Pages 1–2.\n"), ["dash"]);
		assert.deepEqual(rulesHit("The Indonesia–Khmer border.\n"), []);
	});

	test("quotes, arrows, and emojis", () => {
		assert.deepEqual(rulesHit("A “quote”.\n"), ["quotes", "quotes"]);
		assert.deepEqual(rulesHit("Parse → exit, or parse -> exit.\n"), ["arrow", "arrow"]);
		assert.deepEqual(rulesHit("Text <!-- a comment --> here.\n"), []);
		assert.deepEqual(rulesHit("Done 🎉.\n"), ["emoji"]);
	});

	test("Phase N mid-sentence", () => {
		assert.deepEqual(rulesHit("We start Phase 0 now.\n"), ["phase-case"]);
		assert.deepEqual(rulesHit("Phase 0 starts. Phase 1 follows.\n"), []);
		assert.deepEqual(rulesHit("| Phase 1 | Done |\n- Phase 2\n[Phase 3](a.md) is later.\n"), []);
	});

	test("dates", () => {
		assert.deepEqual(rulesHit("On Oct 14, 2026.\n"), ["date"]);
		assert.deepEqual(rulesHit("On 14 October 2026.\n"), ["date"]);
		assert.deepEqual(rulesHit("In October 2026.\n"), ["date"]);
		assert.deepEqual(rulesHit("On 10/14/2026.\n"), ["date"]);
		assert.deepEqual(rulesHit("On 2026-10-14. You may 2 things.\n"), []);
	});

	test("GitHub links must be pinned", () => {
		assert.deepEqual(rulesHit("[x](https://github.com/o/r/blob/main/a.md)\n"), ["pinned-source"]);
		assert.deepEqual(rulesHit("[x](https://github.com/o/r/tree/dd20190/src)\n"), []);
		assert.deepEqual(rulesHit("[x](https://github.com/o/r/blob/v1.2.0/a.md)\n"), []);
	});

	test("inflated words and metaphor nouns, with their forms", () => {
		assert.deepEqual(rulesHit("A robust design that enhances and is enhancing.\n"), ["inflated-word", "inflated-word", "inflated-word"]);
		assert.deepEqual(rulesHit("Our north star and our substrates.\n"), ["metaphor-noun", "metaphor-noun"]);
		assert.deepEqual(rulesHit("Use `robust` here. [a](https://example.com/robust).\n"), []);
	});

	test("procedure words only in numbered steps", () => {
		assert.deepEqual(rulesHit("1. Simply run it, please.\n"), ["procedure-word", "procedure-word"]);
		assert.deepEqual(rulesHit("1. Release-please opens a PR.\n"), []);
		assert.deepEqual(rulesHit("It is easy.\n"), []);
	});

	test("Title Case headings", () => {
		const body = "The tuner client uses a protocol.\n";

		assert.deepEqual(rulesHit(`# Tuner Client Protocol\n${body}`), ["heading-case"]);
		assert.deepEqual(rulesHit(`# Tuner client protocol\n${body}`), []);
		assert.deepEqual(rulesHit(`# Phase 0: Prove the client\n${body}`), []);
		// "Lua" and "FireTuner" never appear in lowercase, so they are proper nouns.
		assert.deepEqual(rulesHit(`# Lua and FireTuner\n${body}`), []);
	});

	test("writing.md itself is skipped", () => {
		assert.deepEqual(checkWriting(buildRepo({ "docs/rules/writing.md": `${writingRules}Robust — “x” →\n` })), []);
	});
});

describe("writing rule table", () => {
	const realWritingRules = fs.readFileSync(path.resolve(import.meta.dirname, "../../docs/rules/writing.md"), "utf8");
	const rules = [...fixedRules, ...wordRules(realWritingRules)];

	test("every pattern is global, so matchAll works", () => {
		for (const rule of rules) assert.ok(rule.pattern.global, `${rule.rule} pattern needs the g flag`);
	});

	test("every example is caught by its own rule", () => {
		for (const rule of rules) {
			const matches = [...rule.example.matchAll(rule.pattern)].filter((m) => !rule.allow?.(rule.example, m));

			assert.ok(matches.length > 0, `${rule.rule} does not catch its example "${rule.example}"`);
		}
	});

	test("the word lists load from the real writing.md", () => {
		assert.ok("delve".match(rules.find((r) => r.rule === "inflated-word").pattern));
		assert.ok("scaffolding".match(rules.find((r) => r.rule === "metaphor-noun").pattern));
	});
});

describe("length", () => {
	test("warns only over the limit", () => {
		const doc = (n) => Array.from({ length: n }, (_, i) => `Line ${i}.`).join("\n");

		assert.deepEqual(checkLength(buildRepo({ "docs/a.md": doc(MAX_LINES) })), []);

		const [warning] = checkLength(buildRepo({ "docs/a.md": doc(MAX_LINES + 1) }));
		
		assert.equal(warning.warning, true);
		assert.equal(warning.line, MAX_LINES + 1);
	});
});
