// The schema for the diplomacy section of the state: where the player stands
// with each player they have met, as the Intel Report shows it. The core mod
// builds it in Scripts/State/SentientSystemsCore_StateDiplomacy.lua.

import { z } from "zod";

const SIDES = z.object({ mine: z.boolean(), theirs: z.boolean() });

export const DIPLOMACY = z.array(z.object({
	player: z.number(),
	atWar: z.boolean(),
	state: z.string().optional().describe(
		"How they see the player, a DIPLO_STATE_ type such as DIPLO_STATE_FRIENDLY. Left out for a human player and, once agents exist, for an agent.",
	),
	turnsLeft: z.number().optional().describe("Of a declared friendship or a denouncement."),
	access: z.object({ level: z.number(), name: z.string() }),
	government: z.string().optional().describe("Or anarchyTurns, while they are in anarchy."),
	anarchyTurns: z.number().optional(),
	agreements: z.object({
		delegation: SIDES,
		embassy: SIDES,
		openBorders: z.object({ received: z.boolean(), given: z.boolean() }),
		defensivePact: z.boolean(),
		researchAgreement: z.string().optional().describe("A tech type."),
		jointWar: z.boolean(),
	}),
	relationship: z.object({
		reasons: z.array(z.object({
			score: z.number(),
			text: z.string().optional(),
			unknown: z.literal(true).optional(),
		})).describe("Best first."),
	}).optional().describe("Left out for a player that is not human or an agent."),
	agendas: z.object({
		list: z.array(z.object({ type: z.string(), name: z.string(), description: z.string() })).describe(
			"The historical agenda first, then the random ones when the access level shows them.",
		),
		hidden: z.number().describe("The number of random agendas that the access level doesn't show."),
	}).optional().describe("Left out for a player that is not human or an agent."),
	grievances: z.object({
		balance: z.number().describe("Positive when the player has grievances against them."),
		perTurn: z.number(),
		log: z.array(z.object({
			turn: z.number(),
			from: z.number(),
			against: z.number(),
			amount: z.number(),
			text: z.string().optional(),
		})).describe("By turn."),
	}).optional().describe("Left out without Gathering Storm."),
	others: z.array(z.object({ player: z.number(), state: z.string() })).optional().describe(
		"How each other player they have met sees them. Left out for neutral ones and when there are none.",
	),
	alliance: z.object({
		level: z.number(),
		max: z.literal(true).optional().describe("There at the highest level, in place of the points."),
		points: z.number().optional(),
		pointsNeeded: z.number().optional(),
		type: z.string().optional().describe("There, with the next two, while allied."),
		pointsPerTurn: z.number().optional(),
		turnsUntilExpiration: z.number().optional(),
	}).optional().describe("Left out without Rise and Fall."),
}).describe("One met player, in ID order."));
