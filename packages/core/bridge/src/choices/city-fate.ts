// The schema for the city fate choice: what to do with a captured city, as
// the raze screen offers it, or a rebelled one, as the disloyal city screen
// offers it.

import { z } from "zod";
import { POSITION } from "../schemas.js";

export const CITY_FATE_CHOICE = z.array(z.object({
	kind: z.enum(["captured", "disloyal"]),
	city: z.number(),
	name: z.string(),
	...POSITION.shape,
	population: z.number(),
	districts: z.number().describe("Those toward the population limit."),
	options: z.array(z.object({
		type: z.string().describe(
			"A CityDestroyDirectives name: LIBERATE_FOUNDER, LIBERATE_PREVIOUS_OWNER, KEEP, or RAZE for a captured city, and KEEP or REJECT for a disloyal one.",
		),
		player: z.number().optional().describe("For a liberate option, the ID of who gets the city."),
		description: z.string().optional().describe("The button's tooltip, in the game's language."),
		blocked: z.array(z.string()).optional().describe("The screen's reason when the city can't be razed."),
	})),
})).optional().describe(
	"Left out of the choices with no captured or rebelled city. The game offers one city at a time, so it holds the next captured city, then the next rebelled one, each when there is one.",
);
