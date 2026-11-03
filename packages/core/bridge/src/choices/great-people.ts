// The schema for the great person choice: the great people the player can recruit or pass now, as the
// Great People screen offers them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesGreatPeople.lua. Patronage, which isn't a blocker, is in
// the state.

import { z } from "zod";

export const GREAT_PEOPLE_CHOICE = z.array(z.object({
	type: z.string().describe("Such as GREAT_PERSON_INDIVIDUAL_ARYABHATA."),
	recruit: z.boolean().describe("True when the player can recruit them."),
	passCost: z.number().optional().describe("The points passing costs. There when the player can pass."),
})).optional().describe(
	"In the screen's order. Left out of the choices unless the player can recruit or pass a great person.",
);
