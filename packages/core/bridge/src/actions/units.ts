// The unit actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsUnits.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Moves a unit to a tile by the game's own path, over as many turns as it
// takes. An ok result means the game took the request, not that the unit has
// arrived.
export function moveUnit(client: TunerClient, playerID: number, unitID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveUnit(${playerID}, ${unitID}, ${x}, ${y})`);
}
