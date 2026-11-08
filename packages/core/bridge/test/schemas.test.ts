// Tests for schemas.ts.

import { describe, expect, test } from "vitest";
import { CITY_REF } from "../src/schemas.js";

describe("CITY_REF", () => {
	test("reads a city's owner, ID, and name", () => {
		expect(CITY_REF.parse({ owner: 0, id: 65536, name: "Rome" })).toEqual({ owner: 0, id: 65536, name: "Rome" });
	});

	test("rejects a city with no owner", () => {
		expect(CITY_REF.safeParse({ id: 65536, name: "Rome" }).success).toBe(false);
	});
});
