// The schema for the dedication choice: the dedications the player may make for the era that began,
// as the dedication popup offers them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesDedications.lua.

import { z } from "zod";

export const DEDICATIONS_CHOICE = z.object({
	era: z.string().describe("The name of the era that began."),
	age: z.enum(["heroic", "golden", "dark", "normal"]).describe("The player's age for the era that ended."),
	picks: z.number().describe("How many dedications the player must make, which is several in a heroic age."),
	options: z.array(z.object({
		type: z.string().describe("The dedication the choice sends, such as COMMEMORATION_SCIENTIFIC."),
		name: z.string().describe("The popup's category text."),
		description: z.string().describe("Its bonus for the age, in the game's language, with its markup."),
	})),
}).optional().describe(
	"Left out of the choices with no dedication to make: there only while the dedication blocker is up.",
);
