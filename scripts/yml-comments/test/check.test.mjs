// Tests for check.mjs: the doc path rule runs on yml comments only.

import { describe, expect, test } from "vitest";
import { checkComments } from "../src/check.mjs";

const files = new Set(["docs/findings/game-api.md"]);
const docs = { exists: (p) => files.has(p) };

describe("checkComments", () => {
	test("names the file, line, and message for a path that doesn't exist", () => {
		const { lines, exitCode } = checkComments({ "a.yml": "on: push\n# see docs/findings/old.md\n" }, docs);

		expect(lines).toEqual(["a.yml:2: docs/findings/old.md does not exist"]);
		expect(exitCode).toBe(1);
	});

	test("reads a comment after a value", () => {
		expect(checkComments({ "a.yml": "run: make # docs/findings/old.md\n" }, docs).lines).toHaveLength(1);
	});

	test("reads a file with Windows line endings", () => {
		expect(checkComments({ "a.yml": "on: push\r\n# docs/findings/old.md\r\n" }, docs).lines).toEqual(["a.yml:2: docs/findings/old.md does not exist"]);
	});

	test("lets through a path that exists and a planned path", () => {
		const text = "# see docs/findings/game-api.md.\n# and docs/reference/tools.md*\n";

		expect(checkComments({ "a.yml": text }, docs)).toEqual({ lines: [], exitCode: 0 });
	});

	test("skips a path that isn't in a comment", () => {
		expect(checkComments({ "a.yml": "path: docs/findings/old.md\nurl: a#docs/findings/old.md\n" }, docs).lines).toEqual([]);
	});

	test("checks every file", () => {
		const text = "# docs/findings/old.md\n";

		expect(checkComments({ "a.yml": text, "b.yml": text }, docs).lines).toHaveLength(2);
	});
});
