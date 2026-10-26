// The schema for the captured city choice: what the player can do with the next city they captured,
// as the raze screen offers it, and with the next city that rebelled to join them, as Rise and
// Fall's disloyal city screen offers it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesCapturedCities.lua.

import { z } from "zod";

// Left out of the choices with no captured or rebelled city. The game offers one city at a time, so
// it holds the next captured city, then the next rebelled one, each when there is one. kind is
// captured or disloyal. districts counts those toward the population limit. Each option's type is a
// CityDestroyDirectives name: LIBERATE_FOUNDER, LIBERATE_PREVIOUS_OWNER, KEEP, or RAZE for a
// captured city, and KEEP or REJECT for a disloyal one. A liberate option has player, the ID of who
// gets the city. description is the button's tooltip, in the game's language, and blocked is the
// screen's reason when the city can't be razed.
export const CAPTURED_CITIES_CHOICE = z.array(z.object({
	kind: z.enum(["captured", "disloyal"]),
	city: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	districts: z.number(),
	options: z.array(z.object({
		type: z.string(),
		player: z.number().optional(),
		description: z.string().optional(),
		blocked: z.array(z.string()).optional(),
	})),
})).optional();
