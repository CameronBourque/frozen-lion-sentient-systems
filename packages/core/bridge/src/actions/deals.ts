// The deal, war, and peace actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsDeals.lua.

import { setTimeout as sleep } from "node:timers/promises";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Accepts or rejects the deal that another player has put to the player, from
// the proposals in the state. An ok result means the game took the answer and
// the session closed.
export function respondToDeal(client: TunerClient, playerID: number, otherPlayerID: number, accept: boolean): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_RespondToDeal(${playerID}, ${otherPlayerID}, ${accept})`);
}

// Declares a surprise war on the other player, a major civ or a city-state. It
// fails for a player not met or already at war, and with the game's reasons
// when the game doesn't allow the war.
export function declareWar(client: TunerClient, playerID: number, otherPlayerID: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_DeclareWar(${playerID}, ${otherPlayerID})`);
}

// How long proposePeace waits for an AI to answer, and how often it asks. An
// AI answered within a second in a single-player game.
export const PEACE_WAIT = { timeoutMs: 5000, intervalMs: 250 };

// Proposes peace to the other player, a major civ or a city-state, then waits
// for the war to end. An ok result means peace is in place. It fails with the
// game's reasons when peace isn't allowed yet, and when the war goes on after
// the wait, which is how an AI's refusal shows.
export async function proposePeace(client: TunerClient, playerID: number, otherPlayerID: number, wait = PEACE_WAIT): Promise<ActionResult> {
	const sent = await sendAction(client, `SentientSystems_ProposePeace(${playerID}, ${otherPlayerID})`);

	if (!sent.ok) {
		return sent;
	}

	const deadline = Date.now() + wait.timeoutMs;
	let result = await sendAction(client, `SentientSystems_GetPeaceResult(${playerID}, ${otherPlayerID})`);

	while (!result.ok && Date.now() < deadline) {
		await sleep(wait.intervalMs);
		result = await sendAction(client, `SentientSystems_GetPeaceResult(${playerID}, ${otherPlayerID})`);
	}

	return result;
}
