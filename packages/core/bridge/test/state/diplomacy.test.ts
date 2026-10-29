// Tests for diplomacy.ts: the schema for the diplomacy section.

import { describe, expect, test } from "vitest";
import { DIPLOMACY } from "../../src/state/diplomacy.js";

const MENELIK = {
	player: 8,
	atWar: false,
	state: "DIPLO_STATE_FRIENDLY",
	access: { level: 1, name: "Limited" },
	government: "GOVERNMENT_AUTOCRACY",
	agreements: {
		delegation: { mine: false, theirs: true },
		embassy: { mine: false, theirs: false },
		openBorders: { received: true, given: false },
		defensivePact: false,
		jointWar: false,
	},
	alliance: { level: 1, points: 0, pointsNeeded: 40 },
};

describe("DIPLOMACY", () => {
	test("accepts a player with an alliance and one without", () => {
		const allied = {
			...MENELIK,
			player: 9,
			turnsLeft: 5,
			alliance: { level: 2, points: 34, pointsNeeded: 80, type: "ALLIANCE_RESEARCH", pointsPerTurn: 1.25, turnsUntilExpiration: 3 },
		};

		expect(DIPLOMACY.parse([MENELIK, allied])).toEqual([MENELIK, allied]);
	});

	test("accepts a human player with no state, and no alliance without Rise and Fall", () => {
		const human = { ...MENELIK, state: undefined, alliance: undefined, anarchyTurns: 3, government: undefined };

		expect(DIPLOMACY.parse([human])).toEqual([human]);
	});

	test("accepts the relationship, agendas, grievances, and others", () => {
		const full = {
			...MENELIK,
			relationship: { reasons: [{ score: 9, text: "Pleased" }, { score: 6, unknown: true as const }] },
			agendas: { list: [{ type: "AGENDA_DEVOUT", name: "Devout", description: "Likes faith" }], hidden: 1 },
			grievances: { balance: 55, perTurn: 0, log: [{ turn: 20, from: 10, against: 0, amount: 50, text: "War declared" }] },
			others: [{ player: 3, state: "DIPLO_STATE_FRIENDLY" }],
		};

		expect(DIPLOMACY.parse([full])).toEqual([full]);
	});

	test("rejects a reason without its score", () => {
		expect(DIPLOMACY.safeParse([{ ...MENELIK, relationship: { reasons: [{ text: "Pleased" }] } }]).success).toBe(false);
	});

	test("accepts the highest alliance level with max", () => {
		const maxed = { ...MENELIK, alliance: { level: 3, max: true as const } };

		expect(DIPLOMACY.parse([maxed])).toEqual([maxed]);
	});

	test("rejects a player without their agreements", () => {
		expect(DIPLOMACY.safeParse([{ ...MENELIK, agreements: undefined }]).success).toBe(false);
	});
});
