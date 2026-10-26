// The schema for the great people section of the state: each great person on offer, with their era,
// cost, effects, patronage costs, and each major player's progress toward them, as the Great People
// screen shows them. The core mod builds it in Scripts/State/SentientSystemsCore_StateGreatPeople.lua.

import { z } from "zod";

// A patronage cost, and whether the screen's button for it is on.
const PATRONAGE_COST = z.object({ cost: z.number(), can: z.boolean() });

// The great people on offer, in the screen's order. A class whose great person someone has claimed
// is left out.
export const GREAT_PEOPLE = z.array(z.object({
	// The class, such as GREAT_PERSON_CLASS_GENERAL, the person, such as
	// GREAT_PERSON_INDIVIDUAL_SUN_TZU, their name and era, and cost, the points to recruit them.
	class: z.string(),
	type: z.string(),
	name: z.string(),
	era: z.string(),
	cost: z.number(),
	// The passive effect, in the game's language. Left out for a great person with none.
	passive: z.string().optional(),
	// The action's name, where to use it, its effect, in the game's language, and its charges, there
	// only above 0. Left out for a great person with no action.
	action: z.object({ name: z.string(), usage: z.string(), effect: z.string(), charges: z.number().optional() }).optional(),
	// The gold and faith costs to recruit them now, each there only when the screen shows its button.
	// Left out while the player can recruit or pass them, or can't earn them.
	patronage: z.object({ gold: PATRONAGE_COST.optional(), faith: PATRONAGE_COST.optional() }).optional(),
	// Why the player can't earn them, in the game's language.
	cantEarn: z.string().optional(),
	// Each major player's points and points per turn toward the class, most points first, each
	// rounded to the nearest tenth. player is the ID of the player or one they have met, and unmet is
	// true in its place for one they haven't met.
	progress: z.array(z.object({
		player: z.number().optional(),
		unmet: z.literal(true).optional(),
		points: z.number(),
		perTurn: z.number(),
	})),
}));
