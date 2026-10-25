// Reads the summary table at the end of a luacov report, checks its total against the threshold,
// and returns the lines to print and the exit code.

// The same threshold as the TypeScript coverage in vitest.config.js.
export const THRESHOLD = 98;

// Returns the summary table, from its "Summary" heading to the end, or null when the report has none.
export function summarySection(report) {
	const text = report.replaceAll("\r\n", "\n");
	const start = text.search(/^Summary$/m);

	return start === -1 ? null : text.slice(start).trimEnd();
}

// Returns the total line coverage in percent, from the table's "Total" row, or null.
export function totalCoverage(summary) {
	const match = /^Total\s+\d+\s+\d+\s+([\d.]+)%$/m.exec(summary);

	return match ? Number(match[1]) : null;
}

export function checkCoverage(report, threshold = THRESHOLD) {
	const summary = summarySection(report);
	const total = summary === null ? null : totalCoverage(summary);

	if (total === null) return { summary, lines: ["The luacov report has no summary table with a Total row."], exitCode: 1 };

	if (total < threshold) return { summary, lines: [summary, `Lua line coverage is ${total}%, under the ${threshold}% threshold.`], exitCode: 1 };

	return { summary, lines: [summary, `Lua line coverage is ${total}%.`], exitCode: 0 };
}
