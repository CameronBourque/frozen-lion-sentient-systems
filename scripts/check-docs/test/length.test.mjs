// Tests for length.mjs, check 5.

import { describe, expect, test } from "vitest";
import { checkLength, MAX_LINES } from "../src/length.mjs";
import { buildRepo } from "../src/parse.mjs";
import { textOfLength } from "./helpers.mjs";

describe("length", () => {
	test("warns only over the limit", () => {
		expect(checkLength(buildRepo({ "docs/a.md": textOfLength(MAX_LINES) }))).toEqual([]);

		const [warning] = checkLength(buildRepo({ "docs/a.md": textOfLength(MAX_LINES + 1) }));

		expect(warning.warning).toBe(true);
		expect(warning.line).toBe(MAX_LINES + 1);
	});
});
