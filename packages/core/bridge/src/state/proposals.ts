// The schema for the proposals section of the state: the deals other players
// have put to the player, as the deal screen shows them.

import { z } from "zod";

const ITEM = z.object({
	id: z.number(),
	kind: z.enum(["gold", "resource", "agreement", "city", "greatWork", "captive", "unit", "technology", "favor"]),
	amount: z.number().optional().describe("For gold, favor, and resources."),
	turns: z.number().optional().describe("Left out for an item that happens once."),
	resource: z.string().optional(),
	agreement: z.string().optional().describe("Such as DIPLOACTION_OPEN_BORDERS."),
	tech: z.string().optional().describe("For a research agreement."),
	allianceType: z.string().optional().describe("For an alliance."),
	target: z.number().optional().describe("A player ID, for a joint war."),
	war: z.string().optional().describe("The war type, for a joint war."),
	city: z.object({ owner: z.number(), id: z.number() }).optional(),
	cedeOccupied: z.literal(true).optional().describe("For a city ceded back."),
	greatWork: z.string().optional(),
	name: z.string().optional().describe("The game's text for a city, great work, captive, unit, or tech."),
	with: z.number().optional().describe(
		"The ID of the item that this one comes with, such as a city's resources and great works.",
	),
	unacceptable: z.literal(true).optional().describe("Left out unless true."),
	locked: z.literal(true).optional().describe("Left out unless true."),
});

export const PROPOSALS = z.array(z.object({
	from: z.number(),
	gift: z.boolean(),
	valid: z.boolean(),
	asks: z.array(ITEM).describe("What the proposal asks the player to give."),
	offers: z.array(ITEM).describe("What the other player gives."),
}));
