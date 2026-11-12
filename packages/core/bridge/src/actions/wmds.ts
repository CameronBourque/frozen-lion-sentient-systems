// The missile silo strike, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsWmds.lua. A unit's strike is the
// wmd_strike order in units.ts.

import type { Position } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Launches a device, such as WMD_NUCLEAR_DEVICE, from the player's missile silo
// at a tile. An ok result means the game took the request.
export function siloStrike(client: TunerClient, playerID: number, silo: Position, target: Position, device: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_SiloStrike(${playerID}, ${silo.x}, ${silo.y}, ${target.x}, ${target.y}, ${JSON.stringify(device)})`);
}
