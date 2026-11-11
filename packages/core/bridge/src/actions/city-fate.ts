// The city fate action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsCityFate.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// What to do with a captured or rebelled city: the type of an option of the
// cityFates choice.
export type CityDirective = "LIBERATE_FOUNDER" | "LIBERATE_PREVIOUS_OWNER" | "KEEP" | "RAZE" | "REJECT";

// Decides the fate of a captured or rebelled city from the cityFates choice.
// An ok result means the game took the request.
export function decideCity(client: TunerClient, playerID: number, cityID: number, directive: CityDirective): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_DecideCity(${playerID}, ${cityID}, ${JSON.stringify(directive)})`);
}
