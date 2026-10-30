// The schema for the dedication choice: the dedications the player may make for the era that began,
// as the dedication popup offers them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesDedications.lua.

import { z } from "zod";

// Left out of the choices with no dedication to make. era is the name of the era that began, age is
// the player's age for the one that ended, picks is how many dedications the player must make, which
// is several in a heroic age, and options lists the dedications on offer, each with type, the
// dedication the choice sends, name, the popup's category text, and description, its bonus for the
// age, in the game's language.
export const DEDICATIONS_CHOICE = z.object({
	era: z.string(),
	age: z.enum(["heroic", "golden", "dark", "normal"]),
	picks: z.number(),
	options: z.array(z.object({ type: z.string(), name: z.string(), description: z.string() })),
}).optional();
