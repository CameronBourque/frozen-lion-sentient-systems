// The schema for the great people section of the state: each great person on offer, as the Great
// People screen shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateGreatPeople.lua.

import { z } from "zod";

// A patronage cost, and whether the screen's button for it is on.
const PATRONAGE_COST = z.object({ cost: z.number(), can: z.boolean() });

export const GREAT_PEOPLE = z.array(z.object({
	class: z.string().describe("Such as GREAT_PERSON_CLASS_GENERAL."),
	type: z.string().describe("The person, such as GREAT_PERSON_INDIVIDUAL_SUN_TZU."),
	name: z.string(),
	era: z.string(),
	cost: z.number().describe("The points to recruit them."),
	passive: z.string().optional().describe(
		"The passive effect, in the game's language. Left out for a great person with none.",
	),
	action: z.object({
		name: z.string(),
		usage: z.string().describe("Where to use it."),
		effect: z.string(),
		charges: z.number().optional().describe("There only above 0."),
	}).optional().describe("In the game's language. Left out for a great person with no action."),
	patronage: z.object({ gold: PATRONAGE_COST.optional(), faith: PATRONAGE_COST.optional() }).optional().describe(
		"The gold and faith costs to recruit them now, each there only when the screen shows its button. Left out while the player can recruit or pass them, or can't earn them.",
	),
	cantEarn: z.string().optional().describe("Why the player can't earn them, in the game's language."),
	progress: z.array(z.object({
		player: z.number().optional().describe("The ID of the player or one they have met."),
		unmet: z.literal(true).optional().describe("There in place of player for one they haven't met."),
		points: z.number(),
		perTurn: z.number(),
	})).describe(
		"Each major player's points and points per turn toward the class, most points first, each rounded to the nearest tenth.",
	),
})).describe(
	"The great people on offer, in the screen's order. A class whose great person someone has claimed is left out.",
);
