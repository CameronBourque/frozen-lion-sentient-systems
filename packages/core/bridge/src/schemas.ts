// Schemas that several sections of the state, the choices, and the placement
// share.

import { z } from "zod";

// A city named by its owner and ID, as the actions take it, with its name.
export const CITY_REF = z.object({ owner: z.number(), id: z.number(), name: z.string().describe("In the game's language.") });
