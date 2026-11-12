// The World Congress actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsWorldCongress.lua.

import type { ResolutionOption } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// One vote on a resolution of the worldCongress choice, named by its type,
// with option A or B, the index of one of its targets, and the number of votes.
export interface ResolutionVote {
	type: string;
	option: ResolutionOption;
	target: number;
	votes: number;
}

// One vote on a proposal of the worldCongress choice, named by its type and
// target, with the number of votes, and against to oppose it.
export interface ProposalVote {
	type: string;
	target: number;
	votes: number;
	against?: boolean;
}

export type CongressVote = ResolutionVote | ProposalVote;

function luaVote(vote: CongressVote): string {
	const side = "option" in vote ? `option = ${JSON.stringify(vote.option)}` : `against = ${vote.against === true}`;

	return `{ type = ${JSON.stringify(vote.type)}, target = ${vote.target}, votes = ${vote.votes}, ${side} }`;
}

// Casts the player's votes in a World Congress session and submits them. Every
// resolution needs a vote, and a proposal left out is an abstention. An ok
// result means the game took the votes, not that the session is over.
export function voteInCongress(client: TunerClient, playerID: number, votes: CongressVote[]): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_VoteInCongress(${playerID}, {${votes.map(luaVote).join(", ")}})`);
}

// A proposal from the available ones of the worldCongress choice, named by its
// type and target.
export interface AvailableProposal {
	type: string;
	target: number;
}

// Calls a Special Session for the proposals and marks the congress as looked
// at. An empty list only marks it. An ok result means the game took the
// proposals, not that a session will meet.
export function proposeInCongress(client: TunerClient, playerID: number, proposals: AvailableProposal[]): Promise<ActionResult> {
	const entries = proposals.map((proposal) => `{ type = ${JSON.stringify(proposal.type)}, target = ${proposal.target} }`);

	return sendAction(client, `SentientSystems_ProposeInCongress(${playerID}, {${entries.join(", ")}})`);
}
