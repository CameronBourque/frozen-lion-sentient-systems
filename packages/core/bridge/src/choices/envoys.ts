// The schema for the envoy choice: the city-states the player can send envoys to, as the City-States
// screen's send mode offers them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesEnvoys.lua.

import { z } from "zod";

// Left out of the choices unless the player has envoys to send and some city-state can take one.
// tokens is the envoys to send, and cityStates the player IDs of the city-states the player has met
// and isn't at war with, in the game's order.
export const ENVOY_CHOICE = z.object({
	tokens: z.number(),
	cityStates: z.array(z.number()),
}).optional();
