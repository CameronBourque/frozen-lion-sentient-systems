// The schema for the proposals section of the state. Format:
// docs/design/core/in-game-lua.md.

import { z } from "zod";

const ITEM = z.object({
	id: z.number(),
	kind: z.enum(["gold", "resource", "agreement", "city", "greatWork", "captive", "unit", "technology", "favor"]),
	amount: z.number().optional(),
	// Left out for an item that happens once.
	turns: z.number().optional(),
	resource: z.string().optional(),
	agreement: z.string().optional(),
	tech: z.string().optional(),
	allianceType: z.string().optional(),
	target: z.number().optional(),
	war: z.string().optional(),
	city: z.object({ owner: z.number(), id: z.number() }).optional(),
	cedeOccupied: z.literal(true).optional(),
	greatWork: z.string().optional(),
	name: z.string().optional(),
	// The ID of the item that this one comes with, such as a city's.
	with: z.number().optional(),
	unacceptable: z.literal(true).optional(),
	locked: z.literal(true).optional(),
});

export const PROPOSALS = z.array(z.object({
	from: z.number(),
	gift: z.boolean(),
	valid: z.boolean(),
	// What the proposal asks the player to give, and what it gives.
	asks: z.array(ITEM),
	offers: z.array(ITEM),
}));
