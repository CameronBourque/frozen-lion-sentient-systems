// Tests for summary.mjs: reading a luacov report's summary table and checking its total.

import { describe, expect, test } from "vitest";
import { checkCoverage, summarySection, THRESHOLD, totalCoverage } from "../src/summary.mjs";

// The end of a luacov report, with each file's line counts and the total.
function report(total, newline = "\n") {
	return [
		"==============================================================================",
		"packages/core/mod/Scripts/SentientSystemsCore_Common.lua",
		"==============================================================================",
		"   1 SENTIENTSYSTEMS_TAG = \"[SENTIENTSYSTEMS]\"",
		"",
		"==============================================================================",
		"Summary",
		"==============================================================================",
		"",
		"File                                                  Hits Missed Coverage",
		"--------------------------------------------------------------------------",
		`packages\\core\\mod\\Scripts\\SentientSystemsCore_Common.lua 11   0      ${total}%`,
		"--------------------------------------------------------------------------",
		`Total                                                 11   0      ${total}%`,
		"",
	].join(newline);
}

describe("summarySection", () => {
	test("returns the table from the Summary heading to the end", () => {
		const summary = summarySection(report("100.00"));

		expect(summary.startsWith("Summary\n")).toBe(true);
		expect(summary.endsWith("100.00%")).toBe(true);
		expect(summary).not.toContain("SENTIENTSYSTEMS_TAG");
	});

	test("reads a report with Windows line endings", () => {
		expect(summarySection(report("100.00", "\r\n"))).toBe(summarySection(report("100.00")));
	});

	test("returns null without a Summary heading", () => {
		expect(summarySection("No summary here\n")).toBeNull();
	});
});

describe("totalCoverage", () => {
	test("reads the percent from the Total row", () => {
		expect(totalCoverage(summarySection(report("97.50")))).toBe(97.5);
	});

	test("returns null without a Total row", () => {
		expect(totalCoverage("Summary\nFile Hits Missed Coverage\n")).toBeNull();
	});
});

describe("checkCoverage", () => {
	test("passes at the threshold", () => {
		const { lines, exitCode } = checkCoverage(report(THRESHOLD.toFixed(2)));

		expect(exitCode).toBe(0);
		expect(lines.at(-1)).toBe(`Lua line coverage is ${THRESHOLD}%.`);
	});

	test("fails under the threshold", () => {
		const { lines, exitCode } = checkCoverage(report("97.99"));

		expect(exitCode).toBe(1);
		expect(lines.at(-1)).toBe(`Lua line coverage is 97.99%, under the ${THRESHOLD}% threshold.`);
	});

	test("takes another threshold", () => {
		expect(checkCoverage(report("50.00"), 50).exitCode).toBe(0);
	});

	test("prints the summary table before the result", () => {
		const { summary, lines } = checkCoverage(report("100.00"));

		expect(lines[0]).toBe(summary);
	});

	test("fails without a summary table", () => {
		expect(checkCoverage("No summary here\n")).toEqual({
			summary: null,
			lines: ["The luacov report has no summary table with a Total row."],
			exitCode: 1,
		});
	});

	test("fails with a summary table but no Total row", () => {
		const { summary, exitCode } = checkCoverage("Summary\nFile Hits Missed Coverage\n");

		expect(summary).toBe("Summary\nFile Hits Missed Coverage");
		expect(exitCode).toBe(1);
	});
});
