// The schema for the emergency choice: the emergency the player has to look at,
// as the emergency popup offers it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesEmergencies.lua. Checked in a
// running game against the popup of an ongoing emergency. The blocker's own
// case, with join and reject, hasn't been seen.

import { z } from "zod";

export const EMERGENCIES_CHOICE = z.array(z.object({
	type: z.string().describe("Such as EMERGENCY_CAPTURE_CITY_STATE."),
	name: z.string().describe("In the game's language, as the popup shows it."),
	description: z.string().describe("In the game's language, as the popup shows it."),
	goal: z.string().describe("In the game's language, as the popup shows it."),
	target: z.number().describe("The target's player ID."),
	targetCity: z.string().optional().describe("The target city's name. Left out with none."),
	hostile: z.boolean(),
	turnsLeft: z.number().describe("Negative for a finished emergency."),
	succeeded: z.boolean().optional().describe("For a finished emergency. Left out for one that is going."),
	options: z.array(z.enum(["join", "reject", "acknowledge"])).describe(
		"join and reject for an emergency that hasn't begun, and acknowledge for any other.",
	),
	members: z.array(z.number()).describe("The players' IDs."),
	goals: z.array(z.string()).describe("The goals the popup lists."),
	scoring: z.array(z.string()).optional().describe("How to gain score. Left out for the target."),
	buffs: z.array(z.string()).describe("The temporary buffs."),
	rewards: z.object({ members: z.array(z.string()), target: z.array(z.string()) }).describe(
		"The lines for members and, when hostile, the target.",
	),
})).optional().describe(
	"Left out of the choices with no emergency to look at. The game offers one at a time, so it holds the next one, there only while the emergency blocker is up.",
);
