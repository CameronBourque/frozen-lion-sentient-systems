// The MCP tools for the World Congress: vote in a session, and propose a
// Special Session. Each description is written for the model.
// docs/design/core/mod/actions/world-congress.md has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { type CongressVote, proposeInCongress, voteInCongress } from "../actions/world-congress.js";
import { RESOLUTION_OPTION } from "../schemas.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const VOTE_IN_CONGRESS = `Cast every vote of a World Congress session from get_choices' worldCongress, submit them, and end your turn, as the congress screen's accept does. Call it last in the turn, because it ends the turn.

- A resolution from resolutions needs a vote: its type, option A or B, target, the index of one of its targets, and votes.
- A proposal from proposals is voted on by its type and target, with votes, and against true to oppose it. A proposal left out is an abstention.

votes is from 1 to the most the session allows, and voteCosts gives the total Favor for each count. Votes that cost more than your favor are refused.`;

const PROPOSE_IN_CONGRESS = `Call a Special Session for proposals from get_choices' worldCongress.available, each by its type and target, as the congress screen does out of a session. Each costs Favor, and a disabled one is refused.

Give an empty list to only mark the congress as looked at, which clears the blocker to look at the congress.`;

const VOTE = z.object({
	type: z.string().describe("The resolution's or proposal's type."),
	option: RESOLUTION_OPTION.optional().describe("For a resolution: A or B."),
	target: z.int().describe("For a resolution, a target's index. For a proposal, its target."),
	votes: z.int().describe("How many votes."),
	against: z.boolean().optional().describe("For a proposal: true to oppose it."),
});

export function registerCongressTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "vote_in_congress", VOTE_IN_CONGRESS, z.object({
		votes: z.array(VOTE),
	}), (playerID, { votes }) => voteInCongress(client, playerID, votes.map(({ option, against, ...vote }): CongressVote => (
		// A vote with an option is on a resolution, as the action reads it.
		option === undefined ? { ...vote, against } : { ...vote, option }
	))));
	registerAction(server, context, "propose_in_congress", PROPOSE_IN_CONGRESS, z.object({
		proposals: z.array(z.object({
			type: z.string().describe("The proposal's type."),
			target: z.int().describe("The proposal's target."),
		})),
	}), (playerID, { proposals }) => proposeInCongress(client, playerID, proposals));
}
