// The actions on the Great People screen, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsGreatPeople.lua.

import type { PurchaseYield } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Sends the core mod's call with the player, the great person, and any other
// arguments, each as Lua text.
function sendGreatPerson(client: TunerClient, luaFunction: string, playerID: number, ...args: string[]): Promise<ActionResult> {
	return sendAction(client, `${luaFunction}(${[String(playerID), ...args.map((arg) => JSON.stringify(arg))].join(", ")})`);
}

// Recruits a great person from the greatPeople choice, such as
// GREAT_PERSON_INDIVIDUAL_ARYABHATA, with the player's points.
export function recruitGreatPerson(client: TunerClient, playerID: number, greatPerson: string): Promise<ActionResult> {
	return sendGreatPerson(client, "SentientSystems_RecruitGreatPerson", playerID, greatPerson);
}

// Passes on a great person from the greatPeople choice.
export function passGreatPerson(client: TunerClient, playerID: number, greatPerson: string): Promise<ActionResult> {
	return sendGreatPerson(client, "SentientSystems_PassGreatPerson", playerID, greatPerson);
}

// Recruits a great person from the great people state with gold or faith.
export function patronizeGreatPerson(client: TunerClient, playerID: number, greatPerson: string, yieldName: PurchaseYield): Promise<ActionResult> {
	return sendGreatPerson(client, "SentientSystems_PatronizeGreatPerson", playerID, greatPerson, yieldName);
}
