// The schema for the envoy choice: the city-states the player can send envoys
// to, as the City-States screen's send mode offers them. The core mod builds it
// in Scripts/Choices/SentientSystemsCore_ChoicesEnvoys.lua.

import { z } from "zod";

export const ENVOY_CHOICE = z.object({
	tokens: z.number().describe("The envoys to send."),
	cityStates: z.array(z.number()).describe(
		"The player IDs of the city-states the player has met and isn't at war with, in the game's order.",
	),
}).optional().describe(
	"Left out of the choices unless the player has envoys to send and some city-state can take one.",
);
