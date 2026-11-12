// The World Congress actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsWorldCongress.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// One vote on a proposal of the worldCongress choice, named by its type and
// target, with the number of votes, and against to oppose it.
export interface CongressVote {
	type: string;
	target: number;
	votes: number;
	against?: boolean;
}

function luaVote(vote: CongressVote): string {
	return `{ type = ${JSON.stringify(vote.type)}, target = ${vote.target}, votes = ${vote.votes}, against = ${vote.against === true} }`;
}

// Casts the player's votes in a World Congress session and submits them. A
// proposal left out is an abstention. An ok result means the game took the
// votes, not that the session is over.
export function voteInCongress(client: TunerClient, playerID: number, votes: CongressVote[]): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_VoteInCongress(${playerID}, {${votes.map(luaVote).join(", ")}})`);
}
