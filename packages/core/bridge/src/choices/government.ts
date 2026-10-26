// The schemas for the government and policy choices: the player's government, its policy slots, and
// the policy in each slot, as the government screen's My Government tab shows them, the policies the
// player can slot, as its policy catalog shows them, and every government, as its View Governments
// tab shows them. The core mod builds them in
// Scripts/Choices/SentientSystemsCore_ChoicesGovernment.lua.

import { z } from "zod";

export const GOVERNMENT = z.object({
	// Such as GOVERNMENT_CHIEFDOM. Left out when the player has none, before Code of Laws or in
	// anarchy.
	type: z.string().optional(),
	// Each policy slot in the game's order. slot is the index that the game's policy changes take,
	// and type is the slot type, such as SLOT_MILITARY. policy is left out for an empty slot.
	slots: z.array(z.object({ slot: z.number(), type: z.string(), policy: z.string().optional() })),
});

// The button to pay to change policies and governments, with its cost in yield, YIELD_GOLD or
// YIELD_FAITH. Left out when the screen hides it. blocked is there when the button is disabled, with
// the screen's text when the player can't afford it, and empty while the World Congress is in
// session.
const UNLOCK = z.object({ cost: z.number(), yield: z.string(), blocked: z.array(z.string()).optional() }).optional();

export const POLICIES = z.object({
	// Whether the player can change policies now, after a civic or with an open slot.
	canChange: z.boolean(),
	unlock: UNLOCK,
	// The policies the catalog shows, by slot type, such as SLOT_MILITARY, without the slotted ones.
	// A slot takes a policy of its own type, and a wildcard slot takes any policy. description is the
	// card's text in the game's language, and new is true for one the civic completed this turn
	// unlocks. Left out when there is none.
	options: z.record(
		z.string(),
		z.array(z.object({ type: z.string(), description: z.string(), new: z.literal(true).optional() })),
	).optional(),
});

export const GOVERNMENTS = z.object({
	// Whether the player can change government now, after a civic or with no government yet.
	canChange: z.boolean(),
	unlock: UNLOCK,
	// Every government in the game's order. slots counts each slot type, such as SLOT_MILITARY, and
	// is left out for none. bonuses holds the card's two bonus lines in the game's language, left out
	// for a government with no bonus, and legacyPercent is there when the ruleset has legacy bonuses.
	// influence is the influence points per turn, the points for each threshold, and the envoys each
	// threshold gives. favor is the diplomatic favor per turn, with Gathering Storm. anarchy is the
	// turns of anarchy to switch to it, left out when 0 and for the current one. locked is the civic
	// that unlocks a locked government, or true when the game names none.
	options: z.array(z.object({
		type: z.string(),
		current: z.literal(true).optional(),
		locked: z.union([z.string(), z.literal(true)]).optional(),
		slots: z.record(z.string(), z.number()).optional(),
		bonuses: z.array(z.string()).optional(),
		legacyPercent: z.number().optional(),
		influence: z.object({ perTurn: z.number(), threshold: z.number(), envoys: z.number() }),
		favor: z.number().optional(),
		anarchy: z.number().optional(),
	})),
});
