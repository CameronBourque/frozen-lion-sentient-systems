// Runs every check over the repo's files and returns the lines to print and the
// exit code. index.mjs reads the files and prints the result.

import { buildRepo } from "./parse.mjs";
import { checkLinks } from "./links.mjs";
import { checkIndexes } from "./indexes.mjs";
import { checkSections } from "./sections.mjs";
import { checkWriting } from "./writing.mjs";
import { checkLength } from "./length.mjs";

const checks = [checkLinks, checkIndexes, checkSections, checkWriting, checkLength];

const format = (result) => `${result.file}:${result.line}: ${result.rule}: ${result.message}`;

export function runChecks(files) {
	const repo = buildRepo(files);
	const results = checks.flatMap((check) => check(repo));
	const warnings = results.filter((r) => r.warning);
	const problems = results.filter((r) => !r.warning);
	const lines = [...warnings.map((w) => `${format(w)} (warning)`), ...problems.map(format)];

	if (problems.length === 0) return { lines: [...lines, `Checked ${repo.docs.size} files. No problems.`], exitCode: 0 };

	const plural = problems.length === 1 ? "" : "s";

	return { lines: [...lines, "", `${problems.length} problem${plural} in ${repo.docs.size} files.`], exitCode: 1 };
}
