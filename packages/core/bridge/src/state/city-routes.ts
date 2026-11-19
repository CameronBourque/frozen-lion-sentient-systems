// Reads the trade routes one of the player's cities could start, as the Trade
// Overview's Available Routes tab lists them, through the stash. The core mod
// builds it in SentientSystemsCore_ChoicesTradeRoutes.lua.

import { z } from "zod";
import { DESTINATION } from "../choices/trade-routes.js";
import { CITY_REF } from "../schemas.js";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// Not strict, so a field from a newer core mod is dropped.
export const CITY_ROUTES = z.object({
	city: CITY_REF.describe("The city the routes start from."),
	destinations: z.array(DESTINATION).describe(
		"The cities the game lets a route from the city go to, the player's own first. It needs no trader.",
	),
});

export type CityRoutes = z.infer<typeof CITY_ROUTES>;

export function readCityRoutes(client: TunerClient, playerID: number, cityID: number): Promise<StashResult<CityRoutes>> {
	return readStash(client, `SentientSystems_GetCityRoutes(${playerID}, ${cityID})`, CITY_ROUTES, "city routes");
}
