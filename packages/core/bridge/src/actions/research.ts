// The tech and civic actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsResearch.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Sends the core mod's call that sets the tech or civic in research. The type
// is the type of an option of the techs or civics choice.
function sendResearch(client: TunerClient, luaFunction: string, playerID: number, type: string): Promise<ActionResult> {
	return sendAction(client, `${luaFunction}(${playerID}, ${JSON.stringify(type)})`);
}

// Sets the tech the player researches, such as TECH_MINING, from the techs
// choice. An ok result means the game took the order.
export function setResearch(client: TunerClient, playerID: number, tech: string): Promise<ActionResult> {
	return sendResearch(client, "SentientSystems_SetResearch", playerID, tech);
}

// Sets the civic the player researches, such as CIVIC_MYSTICISM, from the
// civics choice. An ok result means the game took the order.
export function setCivic(client: TunerClient, playerID: number, civic: string): Promise<ActionResult> {
	return sendResearch(client, "SentientSystems_SetCivic", playerID, civic);
}
