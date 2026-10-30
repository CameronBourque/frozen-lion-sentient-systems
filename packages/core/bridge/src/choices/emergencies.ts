// The schema for the emergency choice: the emergency the player has to look at, as the emergency
// popup offers it. The core mod builds it in Scripts/Choices/SentientSystemsCore_ChoicesEmergencies.lua.
// Checked in a running game against the popup of an ongoing emergency. The blocker's own case,
// with join and reject, hasn't been seen.

import { z } from "zod";

// Left out of the choices with no emergency to look at. The game offers one at a time, so it holds
// the next one: type, such as EMERGENCY_CAPTURE_CITY_STATE, name, description, and goal, the popup's
// texts in the game's language, target, the target's player ID, targetCity, the target city's
// name, left out with none, hostile, turnsLeft, negative for a finished emergency, succeeded, true or
// false for a finished emergency and left out for one that is going, and options,
// "join" and "reject" for one that hasn't begun, and "acknowledge" for any other. members lists the
// players' IDs, goals the goals the popup lists, scoring how to gain score, left out for the
// target, buffs the temporary buffs, and rewards the lines for members and, when hostile, the target.
export const EMERGENCIES_CHOICE = z.array(z.object({
	type: z.string(),
	name: z.string(),
	description: z.string(),
	goal: z.string(),
	target: z.number(),
	targetCity: z.string().optional(),
	hostile: z.boolean(),
	turnsLeft: z.number(),
	succeeded: z.boolean().optional(),
	options: z.array(z.enum(["join", "reject", "acknowledge"])),
	members: z.array(z.number()),
	goals: z.array(z.string()),
	scoring: z.array(z.string()).optional(),
	buffs: z.array(z.string()),
	rewards: z.object({ members: z.array(z.string()), target: z.array(z.string()) }),
})).optional();
