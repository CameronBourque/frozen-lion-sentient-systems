// Tests for errors.ts.

import { describe, expect, test } from "vitest";
import { z } from "zod";
import { describeIssue, explainFailure } from "../src/errors.js";
import { TunerLuaError, TunerMissingStateError, TunerTimeoutError } from "../src/tuner/client.js";

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

describe("explainFailure", () => {
	const RETRY = ". The bridge checks again when it reconnects";

	test("adds the retry text to a missing state and a timeout", () => {
		expect(explainFailure(new TunerMissingStateError(), "state request", RETRY)).toBe(
			"The core mod's state SentientSystemsCore_UI isn't loaded. Turn on Sentient Systems Core in Additional Content, then load a game" + RETRY,
		);
		expect(explainFailure(new TunerTimeoutError(), "state request", RETRY)).toBe(
			"The game didn't answer the state request in time, maybe because a game is loading" + RETRY,
		);
	});

	test("gives the first line of a Lua error, with no retry text", () => {
		expect(explainFailure(new TunerLuaError("no player 0\nstack traceback:", []), "state request", RETRY)).toBe("The state request failed in the game: no player 0");
	});

	test("gives the message of any other error, or the value itself", () => {
		expect(explainFailure(new Error("Disconnected"), "state request")).toBe("The state request failed: Disconnected");
		expect(explainFailure("boom", "state request")).toBe("The state request failed: boom");
	});
});
