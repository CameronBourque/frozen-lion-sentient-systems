// The schema for the government choice: the player's government, its policy slots, and the policy in
// each slot, as the government screen's My Government tab shows them. The core mod builds it in
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
