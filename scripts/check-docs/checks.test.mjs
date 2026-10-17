// Tests for the docs check. Run: npm test

import fs from "node:fs";
import path from "node:path";
import { describe, expect, test } from "vitest";
import { buildRepo, parse, resolveLink, slug } from "./parse.mjs";
import { checkLinks } from "./links.mjs";
import { checkIndexes } from "./indexes.mjs";
import { checkSections } from "./sections.mjs";
import { checkWriting } from "./writing.mjs";
import { checkLength, MAX_LINES } from "./length.mjs";
import { fixedRules, wordRules } from "./writing-rules.mjs";
import { runChecks } from "./run.mjs";

const lines = (...rows) => rows.join("\n") + "\n";
const messages = (problems) => problems.map((p) => `${p.file}:${p.line}: ${p.rule}: ${p.message}`);

describe("parse", () => {
	test("slug follows GitHub's anchor rules", () => {
		expect(slug("Step 2: Turn on the tuner")).toBe("step-2-turn-on-the-tuner");
		expect(slug("Game properties (for checkpoint IDs)")).toBe("game-properties-for-checkpoint-ids");
		expect(slug("The `EnableTuner` setting")).toBe("the-enabletuner-setting");
		expect(slug("See [design](design.md)")).toBe("see-design");
	});

	test("repeated headings get numbered anchors", () => {
		const doc = parse("a.md", lines("# A", "## Notes", "## Notes"));

		expect([...doc.anchors]).toEqual(["a", "notes", "notes-1"]);
	});

	test("code blocks and inline code are blanked, and line numbers stay", () => {
		const doc = parse("a.md", lines("# A", "```", "## Not a heading", "```", "~~~", "text", "~~~", "Use `code` here."));

		expect(doc.headings.map((h) => h.text)).toEqual(["A"]);
		expect(doc.text[2]).toBe("");
		expect(doc.text[7]).toBe("Use        here.");
	});

	test("resolveLink handles relative, anchor-only, root, folder, and external links", () => {
		expect(resolveLink("docs/a/b.md", "../c.md#x")).toEqual({ path: "docs/c.md", anchor: "x" });
		expect(resolveLink("docs/a.md", "#x")).toEqual({ path: "docs/a.md", anchor: "x" });
		expect(resolveLink("docs/a.md", "/README.md")).toEqual({ path: "README.md", anchor: undefined });
		expect(resolveLink("docs/a.md", "design/")).toEqual({ path: "docs/design", anchor: undefined });
		expect(resolveLink("docs/a.md", "../")).toEqual({ path: "", anchor: undefined });
		expect(resolveLink("docs/a.md", "https://example.com")).toBe(null);
		expect(resolveLink("docs/a.md", "mailto:a@example.com")).toBe(null);
		expect(resolveLink("docs/a.md", "/")).toEqual({ path: "", anchor: undefined });
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
		expect(messages(checkLinks(repo))).toEqual([
			"docs/a.md:2: link: nope.md does not exist",
			"docs/a.md:2: link: #nope is not a heading in docs/b.md",
		]);
	});

	test("reads reference links, and skips anchors into files that aren't Markdown", () => {
		const repo = buildRepo({
			"README.md": lines("# Root", "[image](docs/image.png#top)", "[ref]: docs/nope.md"),
			"docs/image.png": null,
		});

		expect(messages(checkLinks(repo))).toEqual(["README.md:3: link: docs/nope.md does not exist"]);
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

		expect(checkIndexes(repo)).toEqual([]);
	});

	test("reports a missing README and unlinked children", () => {
		const repo = buildRepo({
			"docs/README.md": "# Docs\n",
			"docs/a.md": "# A\n",
			"docs/sub/b.md": "# B\n",
			"packages/x/notes.md": "# Not under docs\n",
		});

		expect(messages(checkIndexes(repo))).toEqual([
			"docs/README.md:1: index: a.md is not linked from this index",
			"docs/README.md:1: index: sub/ is not linked from this index",
			"docs/sub:1: index: folder has no README.md",
		]);
	});
});

describe("sections", () => {
	const finding = lines("# F", "Status: open.", "## Questions", "## What we know now", "## Method", "## Results", "Date checked: not yet.");

	test("a complete finding passes", () => {
		expect(checkSections(buildRepo({ "docs/findings/f.md": finding }))).toEqual([]);
	});

	test("a finding lists each missing part", () => {
		expect(messages(checkSections(buildRepo({ "docs/findings/f.md": lines("# F", "## Questions") })))).toEqual([
			"docs/findings/f.md:1: sections: finding is missing ## What we know now",
			"docs/findings/f.md:1: sections: finding is missing ## Method",
			"docs/findings/f.md:1: sections: finding is missing ## Results",
			"docs/findings/f.md:1: sections: finding is missing a Status: line",
			"docs/findings/f.md:1: sections: finding is missing a Date checked: line",
		]);
	});

	test("a roadmap step needs its phase link and sections", () => {
		const step = lines("# Step 1", "Part of [phase 0](README.md).", "## Tasks", "## Done when", "## Record");

		expect(checkSections(buildRepo({ "docs/roadmap/phase-0/01-x.md": step }))).toEqual([]);
		expect(checkSections(buildRepo({ "docs/roadmap/phase-0/01-x.md": "# Step 1\n" })).length).toBe(4);
	});

	test("a design file must end with a Decision | Reason table", () => {
		const good = lines("# D", "## Decisions", "", "| Decision | Reason |", "| --- | --- |");
		const wrongHeader = lines("# D", "## Decisions", "", "| Choice | Why |");
		const wrongEnd = lines("# D", "## Decisions", "## Notes");

		expect(checkSections(buildRepo({ "docs/design/d.md": good }))).toEqual([]);
		expect(messages(checkSections(buildRepo({ "docs/design/d.md": wrongHeader })))).toEqual([
			"docs/design/d.md:2: sections: ## Decisions table header must be Decision | Reason",
		]);
		expect(messages(checkSections(buildRepo({ "docs/design/d.md": wrongEnd })))).toEqual([
			"docs/design/d.md:3: sections: design file must end with ## Decisions",
		]);
	});

	test("a design file with no sections, or with no table, fails", () => {
		expect(messages(checkSections(buildRepo({ "docs/design/d.md": "# D\n" })))).toEqual([
			"docs/design/d.md:1: sections: design file must end with ## Decisions",
		]);
		expect(messages(checkSections(buildRepo({ "docs/design/d.md": lines("# D", "## Decisions", "None yet.") })))).toEqual([
			"docs/design/d.md:2: sections: ## Decisions table header must be Decision | Reason",
		]);
	});

	test("READMEs are exempt", () => {
		expect(checkSections(buildRepo({ "docs/design/README.md": "# Design\n", "docs/findings/README.md": "# Findings\n" }))).toEqual([]);
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

describe("length", () => {
	test("warns only over the limit", () => {
		const doc = (n) => Array.from({ length: n }, (_, i) => `Line ${i}.`).join("\n");

		expect(checkLength(buildRepo({ "docs/a.md": doc(MAX_LINES) }))).toEqual([]);

		const [warning] = checkLength(buildRepo({ "docs/a.md": doc(MAX_LINES + 1) }));

		expect(warning.warning).toBe(true);
		expect(warning.line).toBe(MAX_LINES + 1);
	});
});

describe("runChecks", () => {
	// The smallest repo that passes every check.
	const cleanRepo = {
		"docs/README.md": lines("# Docs", "[Rules](rules/README.md)"),
		"docs/rules/README.md": lines("# Rules", "[Writing](writing.md)"),
		"docs/rules/writing.md": lines("# Writing", "**Inflated words.** Robust. Use the plain word.", "**Abstract metaphor nouns.** Wedge. Use the concrete word."),
	};

	test("a clean repo exits 0", () => {
		expect(runChecks(cleanRepo)).toEqual({ lines: ["Checked 3 files. No problems."], exitCode: 0 });
	});

	test("prints warnings first, then problems and a count, and exits 1", () => {
		const longFile = Array.from({ length: MAX_LINES + 1 }, (_, i) => `Line ${i}.`).join("\n");
		const result = runChecks({ ...cleanRepo, "README.md": "# Root\n\nA robust plan.\n", "notes.md": longFile });

		expect(result).toEqual({
			lines: [
				"notes.md:151: length: 151 lines. Aim for under 150 (warning)",
				'README.md:3: inflated-word: "robust". Use the plain word',
				"",
				"1 problem in 5 files.",
			],
			exitCode: 1,
		});
	});

	test("counts more than one problem in the plural", () => {
		const result = runChecks({ ...cleanRepo, "README.md": "# Root\n\nA robust, robust plan.\n" });

		expect(result.lines.at(-1)).toBe("2 problems in 4 files.");
	});
});
