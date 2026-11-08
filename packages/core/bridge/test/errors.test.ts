// Tests for errors.ts.

import { describe, expect, test } from "vitest";
import { z } from "zod";
import { describeIssue } from "../src/errors.js";

// Returns the lines for every issue of parsing value with schema.
function lines(schema: z.ZodType, value: unknown): string[] {
	const parsed = schema.safeParse(value);

	return parsed.success ? [] : parsed.error.issues.flatMap((issue) => describeIssue(issue, "the state"));
}

describe("describeIssue", () => {
	test("names the path of a field", () => {
		expect(lines(z.object({ a: z.object({ b: z.number() }) }), { a: { b: "1" } })).toEqual(["a.b: Invalid input: expected number, received string"]);
	});

	test("names the whole value for an issue with no path", () => {
		expect(lines(z.object({}), 3)).toEqual(["the state: Invalid input: expected object, received number"]);
	});

	test("gives each unknown field a line of its own", () => {
		expect(lines(z.strictObject({ a: z.strictObject({}) }), { a: { x: 1, y: 2 }, z: 3 })).toEqual(["a.x: Unknown field", "a.y: Unknown field", "z: Unknown field"]);
	});
});
