// Tests for sections.mjs, check 3.

import { describe, expect, test } from "vitest";
import { buildRepo } from "./parse.mjs";
import { checkSections } from "./sections.mjs";
import { lines, messages } from "./test-helpers.mjs";

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
