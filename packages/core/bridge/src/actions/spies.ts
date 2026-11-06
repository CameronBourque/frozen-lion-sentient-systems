// The spy actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsSpies.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Starts a mission in the city a spy stands in. The mission is the type of one
// from the spy missions choice. A counterspy mission also names the district to
// guard, such as DISTRICT_CAMPUS. An ok result means the mission has begun, not
// that it has finished.
export function spyMission(client: TunerClient, playerID: number, unitID: number, mission: string, district?: string): Promise<ActionResult> {
	const target = district === undefined ? "nil" : JSON.stringify(district);

	return sendAction(client, `SentientSystems_SpyMission(${playerID}, ${unitID}, ${JSON.stringify(mission)}, ${target})`);
}

// Sends a spy to a destination of the spy missions choice, which names the city
// by its owner and its ID. An ok result means the spy has set out, not that it
// has arrived.
export function spyTravel(client: TunerClient, playerID: number, unitID: number, ownerID: number, cityID: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_SpyTravel(${playerID}, ${unitID}, ${ownerID}, ${cityID})`);
}
