// The great work move action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsGreatWorks.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Where a great work goes, as one slot of the great works state gives it: the
// city's ID, the building's type such as BUILDING_MUSEUM_ART, and the slot's
// number.
export interface GreatWorkSlot {
	city: number;
	building: string;
	slot: number;
}

// Moves the great work with the game's index from the great works state to a
// slot. A slot that holds a work swaps the two. An ok result means the game
// took the request.
export function moveGreatWork(client: TunerClient, playerID: number, workIndex: number, to: GreatWorkSlot): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveGreatWork(${playerID}, ${workIndex}, ${to.city}, ${JSON.stringify(to.building)}, ${to.slot})`);
}
