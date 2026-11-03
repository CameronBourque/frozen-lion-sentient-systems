// The schema for the religion section of the state: the player's pantheon, their progress toward a
// religion, and the religion they founded with its followers, as the religion screen's My Religion
// tab shows them. The core mod builds it in Scripts/State/SentientSystemsCore_StateReligion.lua.

import { z } from "zod";

export const RELIGION = z.object({
	pantheon: z.string().optional().describe(
		"The player's pantheon belief, such as BELIEF_GOD_OF_THE_SEA. Left out before they have one.",
	),
	pantheonFaith: z.number().optional().describe(
		"The faith the next pantheon needs. There only before the player has a pantheon.",
	),
	prophet: z.boolean().optional().describe(
		"Whether the player has a Great Prophet. There only between their pantheon and their first belief.",
	),
	founded: z.object({
		type: z.string().describe("Such as RELIGION_CATHOLICISM."),
		name: z.string(),
		beliefs: z.array(z.string()).describe("By type."),
		holyCity: z.number().optional().describe("A city ID. Left out once no city holds it."),
		majority: z.number().describe("The count of cities where it is the majority religion."),
		cities: z.array(z.object({ owner: z.number(), city: z.number(), followers: z.number() })).describe(
			"Each city of any player with followers of it.",
		),
	}).optional().describe("The religion the player founded. Left out before they found one."),
});
