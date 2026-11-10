// The policy actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsPolicies.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Sets the policy in every slot of the player's government. slots lists each
// slot by its number in the government choice, from 0, with a policy type such
// as POLICY_DISCIPLINE, or null to leave it empty. An ok result means the game
// took the change.
export function setPolicies(client: TunerClient, playerID: number, slots: (string | null)[]): Promise<ActionResult> {
	const entries = slots.map((policy, slot) => `[${slot}] = ${policy === null ? "false" : JSON.stringify(policy)}`);

	return sendAction(client, `SentientSystems_SetPolicies(${playerID}, {${entries.join(", ")}})`);
}

// Pays the cost of the policies choice's unlock, which lets the player change
// policies on a turn with no civic completed. An ok result means the game took
// the request.
export function unlockPolicies(client: TunerClient, playerID: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_UnlockPolicies(${playerID})`);
}

// Changes the player's government to a type from the governments choice, such
// as GOVERNMENT_AUTOCRACY. An ok result means the game took the change. A
// government with anarchy turns starts after them.
export function setGovernment(client: TunerClient, playerID: number, government: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_SetGovernment(${playerID}, ${JSON.stringify(government)})`);
}
