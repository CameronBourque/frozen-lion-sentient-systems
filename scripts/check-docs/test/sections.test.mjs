// Tests for sections.mjs, check 3.

import { describe, expect, test } from "vitest";
import { buildRepo } from "../src/parse.mjs";
import { checkSections } from "../src/sections.mjs";
import { lines, messages } from "./helpers.mjs";

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
		const step = lines("# One", "Part of [phase 0](README.md).", "## Tasks", "## Done when", "## Record");

		expect(checkSections(buildRepo({ "docs/roadmap/phase-0/x.md": step }))).toEqual([]);
		expect(checkSections(buildRepo({ "docs/roadmap/phase-0/x.md": "# One\n" })).length).toBe(4);
		expect(checkSections(buildRepo({ "docs/roadmap/phase-0/README.md": "# Phase 0\n" }))).toEqual([]);
	});

	test("a phase's done.md isn't a roadmap step", () => {
		expect(checkSections(buildRepo({ "docs/roadmap/phase-0/done.md": "# Phase 0: finished steps\n" }))).toEqual([]);
	});

	test("a tech debt file needs its sections, and Questions or Tasks", () => {
		const open = lines("# D", "## Now", "## Proposal", "## Questions", "## Done when");
		const planned = lines("# D", "## Now", "## Proposal", "## Tasks", "## Done when");

		expect(checkSections(buildRepo({ "docs/tech-debt/d.md": open }))).toEqual([]);
		expect(checkSections(buildRepo({ "docs/tech-debt/d.md": planned }))).toEqual([]);
		expect(messages(checkSections(buildRepo({ "docs/tech-debt/d.md": lines("# D", "## Now") })))).toEqual([
			"docs/tech-debt/d.md:1: sections: tech debt file is missing ## Proposal",
			"docs/tech-debt/d.md:1: sections: tech debt file is missing ## Done when",
			"docs/tech-debt/d.md:1: sections: tech debt file is missing ## Questions or ## Tasks",
		]);
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
		expect(checkSections(buildRepo({ "docs/design/README.md": "# Design\n", "docs/findings/README.md": "# Findings\n", "docs/tech-debt/README.md": "# Tech debt\n" }))).toEqual([]);
	});
});
