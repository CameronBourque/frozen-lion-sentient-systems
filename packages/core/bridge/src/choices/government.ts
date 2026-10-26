// The schemas for the government and policy choices: the player's government, its policy slots, and
// the policy in each slot, as the government screen's My Government tab shows them, and the policies
// the player can slot, as its policy catalog shows them. The core mod builds them in
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

export const POLICIES = z.object({
	// Whether the player can change policies now, after a civic or with an open slot.
	canChange: z.boolean(),
	// The button to pay to change policies, with its cost in yield, YIELD_GOLD or YIELD_FAITH. Left
	// out when the screen hides it. blocked is there when the button is disabled, with the screen's
	// text when the player can't afford it, and empty while the World Congress is in session.
	unlock: z.object({ cost: z.number(), yield: z.string(), blocked: z.array(z.string()).optional() }).optional(),
	// The policies the catalog shows, by slot type, such as SLOT_MILITARY, without the slotted ones.
	// A slot takes a policy of its own type, and a wildcard slot takes any policy. description is the
	// card's text in the game's language, and new is true for one the civic completed this turn
	// unlocks. Left out when there is none.
	options: z.record(
		z.string(),
		z.array(z.object({ type: z.string(), description: z.string(), new: z.literal(true).optional() })),
	).optional(),
});
