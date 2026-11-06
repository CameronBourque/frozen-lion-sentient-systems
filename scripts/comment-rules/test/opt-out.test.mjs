// Tests for opt-out.mjs: the marker that skips a heuristic comment rule.

import { describe, expect, test } from "vitest";
import { hasOptOut } from "../src/opt-out.mjs";

describe("hasOptOut", () => {
	test("accepts a marker with a reason", () => {
		expect(hasOptOut(" comment-lint-ignore: section label")).toBe(true);
	});

	test("refuses a marker with no reason", () => {
		expect(hasOptOut(" comment-lint-ignore:")).toBe(false);
		expect(hasOptOut(" comment-lint-ignore:   ")).toBe(false);
	});

	test("refuses a comment with no marker", () => {
		expect(hasOptOut(" a plain comment")).toBe(false);
	});
});
