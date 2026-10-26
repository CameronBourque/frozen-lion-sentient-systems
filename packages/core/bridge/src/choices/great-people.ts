// The schema for the great person choice: the great people the player can recruit or pass now, as the
// Great People screen offers them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesGreatPeople.lua.

import { z } from "zod";

// Left out of the choices unless the player can recruit or pass a great person. Each has type, such as
// GREAT_PERSON_INDIVIDUAL_ARYABHATA, recruit, true when the player can recruit them, and passCost,
// the points passing costs, there when the player can pass.
export const GREAT_PEOPLE_CHOICE = z.array(z.object({
	type: z.string(),
	recruit: z.boolean(),
	passCost: z.number().optional(),
})).optional();
