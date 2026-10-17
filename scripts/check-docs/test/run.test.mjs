// Tests for run.mjs: the output lines and the exit code.

import { describe, expect, test } from "vitest";
import { MAX_LINES } from "../src/length.mjs";
import { runChecks } from "../src/run.mjs";
import { lines, textOfLength } from "./helpers.mjs";

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
		const result = runChecks({ ...cleanRepo, "README.md": "# Root\n\nA robust plan.\n", "notes.md": textOfLength(MAX_LINES + 1) });

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
