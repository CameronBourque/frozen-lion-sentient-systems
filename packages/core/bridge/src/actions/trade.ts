// The trade route action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsTrade.lua. Plunder is a unit
// order in units.ts.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Starts a route from the city a trader stands in to a destination of the
// trade route choice, which names the city by its owner and its ID. An ok
// result means the game took the route, which the trader then travels.
export function tradeRoute(client: TunerClient, playerID: number, unitID: number, ownerID: number, cityID: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_TradeRoute(${playerID}, ${unitID}, ${ownerID}, ${cityID})`);
}
