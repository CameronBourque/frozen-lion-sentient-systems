// The dedication action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsDedications.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Makes the era's dedications, types from the options of the dedications
// choice, such as COMMEMORATION_SCIENTIFIC, with as many as its picks. An ok
// result means the game took them.
export function chooseDedications(client: TunerClient, playerID: number, dedications: string[]): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_ChooseDedications(${playerID}, {${dedications.map((type) => JSON.stringify(type)).join(", ")}})`);
}
