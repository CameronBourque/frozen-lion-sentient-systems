// The governor actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsGovernors.lua. They need Rise and
// Fall.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Appoints a governor from the governors choice, such as GOVERNOR_THE_EDUCATOR,
// with a title. An ok result means the game took the request.
export function appointGovernor(client: TunerClient, playerID: number, governor: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_AppointGovernor(${playerID}, ${JSON.stringify(governor)})`);
}

// Gives an appointed governor a promotion from the governors choice, with a
// title. An ok result means the game took the request.
export function promoteGovernor(client: TunerClient, playerID: number, governor: string, promotion: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_PromoteGovernor(${playerID}, ${JSON.stringify(governor)}, ${JSON.stringify(promotion)})`);
}

// Sends an appointed governor to a city from the governors choice, by its
// owner and ID. An ok result means the game took the request.
export function assignGovernor(client: TunerClient, playerID: number, governor: string, owner: number, cityID: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_AssignGovernor(${playerID}, ${JSON.stringify(governor)}, ${owner}, ${cityID})`);
}
