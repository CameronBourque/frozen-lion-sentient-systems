// The tech and civic actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsResearch.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Sends the core mod's call that researches the tech or civic and the
// prerequisites it needs. The type comes from the techs or civics choice, or
// from the tree. append adds it to the end of the queue in place of replacing
// the queue.
function sendResearch(client: TunerClient, luaFunction: string, playerID: number, type: string, append: boolean): Promise<ActionResult> {
	const args = [playerID, JSON.stringify(type), ...(append ? ["true"] : [])];

	return sendAction(client, `${luaFunction}(${args.join(", ")})`);
}

// Researches a tech, such as TECH_MINING, and the prerequisites it needs, in
// place of the queue. An ok result means the game took the order.
export function setResearch(client: TunerClient, playerID: number, tech: string): Promise<ActionResult> {
	return sendResearch(client, "SentientSystems_SetResearch", playerID, tech, false);
}

// Adds a tech and the prerequisites it needs to the end of the queue.
export function queueResearch(client: TunerClient, playerID: number, tech: string): Promise<ActionResult> {
	return sendResearch(client, "SentientSystems_SetResearch", playerID, tech, true);
}

// Researches a civic, such as CIVIC_MYSTICISM, as setResearch does for a tech.
export function setCivic(client: TunerClient, playerID: number, civic: string): Promise<ActionResult> {
	return sendResearch(client, "SentientSystems_SetCivic", playerID, civic, false);
}

// Adds a civic to the end of the queue, as queueResearch does for a tech.
export function queueCivic(client: TunerClient, playerID: number, civic: string): Promise<ActionResult> {
	return sendResearch(client, "SentientSystems_SetCivic", playerID, civic, true);
}
