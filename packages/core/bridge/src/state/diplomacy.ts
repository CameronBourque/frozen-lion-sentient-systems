// The schema for the diplomacy section of the state. Format:
// docs/design/core/in-game-lua.md.

import { z } from "zod";

const SIDES = z.object({ mine: z.boolean(), theirs: z.boolean() });

export const DIPLOMACY = z.array(z.object({
	player: z.number(),
	atWar: z.boolean(),
	// Left out for a human player.
	state: z.string().optional(),
	turnsLeft: z.number().optional(),
	access: z.object({ level: z.number(), name: z.string() }),
	government: z.string().optional(),
	anarchyTurns: z.number().optional(),
	agreements: z.object({
		delegation: SIDES,
		embassy: SIDES,
		openBorders: z.object({ received: z.boolean(), given: z.boolean() }),
		defensivePact: z.boolean(),
		researchAgreement: z.string().optional(),
		jointWar: z.boolean(),
	}),
	// Left out for a human player.
	relationship: z.object({
		reasons: z.array(z.object({
			score: z.number(),
			text: z.string().optional(),
			unknown: z.literal(true).optional(),
		})),
	}).optional(),
	agendas: z.object({
		list: z.array(z.object({ type: z.string(), name: z.string(), description: z.string() })),
		hidden: z.number(),
	}).optional(),
	// Left out without Gathering Storm.
	grievances: z.object({
		balance: z.number(),
		perTurn: z.number(),
		log: z.array(z.object({
			turn: z.number(),
			from: z.number(),
			against: z.number(),
			amount: z.number(),
			text: z.string(),
		})),
	}).optional(),
	// Left out when empty.
	others: z.array(z.object({ player: z.number(), state: z.string() })).optional(),
	// Left out without Rise and Fall.
	alliance: z.object({
		level: z.number(),
		max: z.literal(true).optional(),
		points: z.number().optional(),
		pointsNeeded: z.number().optional(),
		type: z.string().optional(),
		pointsPerTurn: z.number().optional(),
		turnsUntilExpiration: z.number().optional(),
	}).optional(),
}));
