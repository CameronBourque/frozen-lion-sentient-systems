// Tests for schemas.ts.

import { describe, expect, test } from "vitest";
import { BOOST, CITY_ID, CITY_REF, POSITION, YIELD_AMOUNT, YIELDS } from "../src/schemas.js";

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

describe("POSITION", () => {
	test("reads a tile's x and y", () => {
		expect(POSITION.parse({ x: 12, y: 30 })).toEqual({ x: 12, y: 30 });
	});

	test("rejects a position with no y", () => {
		expect(POSITION.safeParse({ x: 12 }).success).toBe(false);
	});
});

describe("BOOST", () => {
	test("reads a boost's share, trigger, and whether it has triggered", () => {
		const boost = { percent: 40, trigger: "Build a Quarry.", triggered: false };

		expect(BOOST.parse(boost)).toEqual(boost);
	});

	test("rejects a boost with no trigger", () => {
		expect(BOOST.safeParse({ percent: 40, triggered: false }).success).toBe(false);
	});
});

describe("YIELD_AMOUNT", () => {
	test("reads a yield's type and amount", () => {
		expect(YIELD_AMOUNT.parse({ type: "YIELD_CULTURE", amount: 2 })).toEqual({ type: "YIELD_CULTURE", amount: 2 });
	});

	test("rejects an amount that isn't a number", () => {
		expect(YIELD_AMOUNT.safeParse({ type: "YIELD_CULTURE", amount: "2" }).success).toBe(false);
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
