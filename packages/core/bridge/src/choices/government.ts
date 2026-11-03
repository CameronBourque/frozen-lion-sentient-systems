// The schemas for the government and policy choices: the player's government,
// its policy slots, and the policy in each slot, as the government screen's My
// Government tab shows them, the policies the player can slot, as its policy
// catalog shows them, and every government, as its View Governments tab shows
// them. The core mod builds them in
// Scripts/Choices/SentientSystemsCore_ChoicesGovernment.lua.

import { z } from "zod";

// The government's bonuses are left out, as they don't change while it is in
// place.
export const GOVERNMENT = z.object({
	type: z.string().optional().describe(
		"Such as GOVERNMENT_CHIEFDOM. Left out when the player has none, before Code of Laws or in anarchy.",
	),
	slots: z.array(z.object({
		slot: z.number().describe("The index that the game's policy changes take."),
		type: z.string().describe("The slot type, such as SLOT_MILITARY or SLOT_GREAT_PERSON."),
		policy: z.string().optional().describe("Such as POLICY_GOD_KING. Left out for an empty slot."),
	})).describe("Each policy slot in the game's order."),
});

const UNLOCK = z.object({
	cost: z.number().describe("In the yield."),
	yield: z.string().describe("YIELD_GOLD or YIELD_FAITH."),
	blocked: z.array(z.string()).optional().describe(
		"There when the screen disables the button, with its text when the player can't afford it, such as You Need 50 [ICON_GoldLarge] Gold. Empty while the World Congress is in session.",
	),
}).optional().describe("The button to pay to change policies and governments. Left out when the screen hides it.");

export const POLICIES = z.object({
	canChange: z.boolean().describe(
		"Whether the player can change policies now: after a civic completes, with an open slot, or after paying the unlock.",
	),
	unlock: UNLOCK,
	options: z.record(
		z.string(),
		z.array(z.object({
			type: z.string().describe("Such as POLICY_AGOGE."),
			description: z.string().describe("The card's text, in the game's language."),
			new: z.literal(true).optional().describe("True for one the civic completed this turn unlocks."),
		})),
	).optional().describe(
		"The policies the player can slot, by slot type, such as SLOT_MILITARY. A slot takes a policy of its own type, and a wildcard slot takes any policy. A slotted policy is left out, and so is options when none is left.",
	),
});

export const GOVERNMENTS = z.object({
	canChange: z.boolean().describe(
		"Whether the player can change government now: after a civic completes or with no government yet.",
	),
	unlock: UNLOCK.describe(
		"The button to pay to change government. Shown only with a government in place and another unlocked.",
	),
	options: z.array(z.object({
		type: z.string().describe("Such as GOVERNMENT_AUTOCRACY."),
		current: z.literal(true).optional().describe("True for the player's government."),
		locked: z.union([z.string(), z.literal(true)]).optional().describe(
			"The civic that unlocks a locked government, or true when the game names none.",
		),
		slots: z.record(z.string(), z.number()).optional().describe(
			"The count of each slot type, such as SLOT_MILITARY. Left out for none.",
		),
		bonuses: z.array(z.string()).optional().describe(
			"The card's two bonus lines, in the game's language. Left out for a government with no bonus.",
		),
		legacyPercent: z.number().optional().describe("There with the base game's legacy bonuses."),
		influence: z.object({
			perTurn: z.number().describe("Influence points per turn."),
			threshold: z.number().describe("The points for each threshold."),
			envoys: z.number().describe("The envoys each threshold gives."),
		}),
		favor: z.number().optional().describe("Diplomatic favor per turn. There with Gathering Storm."),
		anarchy: z.number().optional().describe(
			"The turns of anarchy to switch to it. Left out when 0 and for the current one.",
		),
	})).describe("Every government, in the game's order."),
});
