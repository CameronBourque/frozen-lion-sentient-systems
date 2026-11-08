// Tests for schemas.ts.

import { describe, expect, test } from "vitest";
import { CITY_ID, CITY_REF, YIELDS } from "../src/schemas.js";

describe("CITY_REF", () => {
	test("reads a city's owner, ID, and name", () => {
		expect(CITY_REF.parse({ owner: 0, id: 65536, name: "Rome" })).toEqual({ owner: 0, id: 65536, name: "Rome" });
	});

	test("rejects a city with no owner", () => {
		expect(CITY_REF.safeParse({ id: 65536, name: "Rome" }).success).toBe(false);
	});
});

describe("CITY_ID", () => {
	test("reads a city's owner and ID, and drops a name", () => {
		expect(CITY_ID.parse({ owner: 0, id: 65536, name: "Rome" })).toEqual({ owner: 0, id: 65536 });
	});
});

describe("YIELDS", () => {
	test("reads the yields that are there, and leaves out the rest", () => {
		expect(YIELDS.parse({ science: 3, faith: 1 })).toEqual({ science: 3, faith: 1 });
	});

	test("rejects a yield that isn't a number", () => {
		expect(YIELDS.safeParse({ food: "2" }).success).toBe(false);
	});
});
