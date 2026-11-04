// Contract test: the JSON that the Lua tests record parses with the schema the
// bridge reads it with, and loses nothing. npm run test:lua writes the
// fixtures, in test/lua-fixtures/, with one folder for each call.

import fs from "node:fs";
import path from "node:path";
import { describe, expect, test } from "vitest";
import type { z } from "zod";
import { CHOICES } from "../src/choices/choices.js";
import { PLACEMENT } from "../src/placement/placement.js";
import { STATE } from "../src/state/state.js";
import { GOVERNOR_TREE } from "../src/trees/governors.js";
import { TREE } from "../src/trees/research.js";

const FIXTURES = path.join(import.meta.dirname, "lua-fixtures");

// The schema that each call's JSON is read with, by the folder the fixtures are
// in.
const CALLS: Record<string, z.ZodType> = {
	GetState: STATE,
	GetChoices: CHOICES,
	GetTechTree: TREE,
	GetCivicTree: TREE,
	GetGovernorTree: GOVERNOR_TREE,
	GetPlacement: PLACEMENT,
};

function fixtureNames(call: string): string[] {
	try {
		return fs.readdirSync(path.join(FIXTURES, call)).filter((name) => name.endsWith(".json"));
	} catch {
		return [];
	}
}

describe.each(Object.entries(CALLS))("%s fixtures", (call, schema) => {
	const names = fixtureNames(call);

	test("exist", () => {
		expect(names.length, `No ${call} fixtures. Run npm run test:lua to write them.`).toBeGreaterThan(0);
	});

	test.each(names)("%s parses with nothing dropped", (name) => {
		const json: unknown = JSON.parse(fs.readFileSync(path.join(FIXTURES, call, name), "utf8"));
		const result = schema.safeParse(json);

		expect(result.error?.message).toBeUndefined();
		// The schemas have no defaults or transforms, so a parse that drops
		// nothing returns the same value.
		expect(result.data).toEqual(json);
	});
});
