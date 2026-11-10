// The pantheon and religion actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsReligion.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Founds the player's pantheon with a belief from the pantheon choice, such as
// BELIEF_RELIGIOUS_SETTLEMENTS. An ok result means the game took the request.
export function foundPantheon(client: TunerClient, playerID: number, belief: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_FoundPantheon(${playerID}, ${JSON.stringify(belief)})`);
}

// Founds the player's religion, a type from the religion choice such as
// RELIGION_BUDDHISM, with the beliefs it offers, a follower belief first. The
// name is for a religion whose customName is true. An ok result means the game
// took the requests.
export function foundReligion(client: TunerClient, playerID: number, religion: string, beliefs: string[], name?: string): Promise<ActionResult> {
	const args = [String(playerID), JSON.stringify(religion), `{${beliefs.map((belief) => JSON.stringify(belief)).join(", ")}}`];

	if (name !== undefined) {
		args.push(JSON.stringify(name));
	}

	return sendAction(client, `SentientSystems_FoundReligion(${args.join(", ")})`);
}
