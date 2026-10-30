// Tests for governors.ts: the schema for the governors to appoint, the promotions to give, and the
// cities to assign them to.

import { describe, expect, test } from "vitest";
import { GOVERNORS_CHOICE } from "../../src/choices/governors.js";

const CHOICE = {
	appoint: [{
		type: "GOVERNOR_THE_DEFENDER",
		name: "Victor",
		title: "The Castellan",
		description: "Military focused, once established in a city, Victor is instrumental in strengthening it.",
		loyalty: 8,
		turnsToEstablish: 3,
	}],
	promote: [{
		governor: "GOVERNOR_THE_MERCHANT",
		promotions: [{ type: "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER", name: "Harbormaster", description: "Double adjacency bonuses from Commercial Hubs and Harbors in the city." }],
	}],
	assign: [{
		governor: "GOVERNOR_THE_AMBASSADOR",
		cities: [{ owner: 0, id: 65536, name: "Rome" }, { owner: 1, id: 65536, name: "Roma", blocked: ["You are at war."] }],
	}],
};

describe("GOVERNORS_CHOICE", () => {
	test("accepts the governors to appoint, promotions, and cities", () => {
		expect(GOVERNORS_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts a Secret Society to appoint, with no loyalty or turns, and a hidden promotion", () => {
		const choice = {
			appoint: [{ type: "GOVERNOR_OWLS_OF_MINERVA", name: "Owls of Minerva", title: "Secret Society", description: "A secret group.", secret: true as const }],
			promote: [{ governor: "GOVERNOR_OWLS_OF_MINERVA", promotions: [{ type: "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3", name: "???", description: "Not yet revealed.", hidden: true as const }] }],
		};

		expect(GOVERNORS_CHOICE.parse(choice)).toEqual(choice);
	});

	test("accepts a choice with only some keys, and no governor choice", () => {
		expect(GOVERNORS_CHOICE.safeParse({ assign: CHOICE.assign }).success).toBe(true);
		expect(GOVERNORS_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a city without its ID", () => {
		expect(GOVERNORS_CHOICE.safeParse({ assign: [{ governor: "GOVERNOR_THE_MERCHANT", cities: [{ owner: 0, name: "Rome" }] }] }).success).toBe(false);
	});
});
