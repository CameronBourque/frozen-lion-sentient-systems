// The MCP tools that deal with other players: envoys, deals, leader screens,
// war, and peace. Each description is written for the model.
// docs/design/core/mod/actions/ has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { declareWar, proposePeace, respondToDeal, respondToSession } from "../actions/deals.js";
import { sendEnvoys } from "../actions/envoys.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SEND_ENVOYS = `Send envoys to a city-state, a player id from get_choices' envoys.cityStates, as the City-States screen does. count is 1 when left out, and at most envoys.tokens.

The envoy blocker stays up until you send every envoy. To keep some for later, end the turn with force.`;

const RESPOND_TO_DEAL = `Accept or reject the deal another player has put to you, from get_state's proposals, by the player in from. The answer covers the whole deal, and the session then closes. A deal whose valid is false can only be rejected.

Read asks and offers before you accept. Accepting a deal with a joint war declares that war.`;

const RESPOND_TO_SESSION = `Answer a leader screen another player has open with you, other than a deal, from get_state's sessions, such as a request, a promise, or a first meeting. option is the key of one of its options, such as CHOICE_POSITIVE. CHOICE_EXIT is the goodbye and closes the session.

The session may go on with another statement, which the next get_state lists. An open session stops end_turn, so answer each one.`;

const DECLARE_WAR = `Declare a surprise war on a major civilization or a city-state you have met. A refusal gives the game's reasons when it doesn't allow the war.

Moves and attacks never declare war on their own, so declare it first.`;

const PROPOSE_PEACE = `Propose peace to a major civilization or a city-state you are at war with, then wait up to 5 seconds for the answer. Ok means peace is in place.

A refusal gives the game's reasons when peace isn't allowed yet, such as the turns to wait after a war is declared, or says the war goes on, which is how an AI's no shows. The game may add what a peace needs, such as an occupied city ceded back.`;

const OTHER_PLAYER = z.int().describe("The other player's id.");

export function registerDiplomacyTools(server: McpServer, context: ToolContext): void {
	registerAction(server, context, "send_envoys", SEND_ENVOYS, z.object({
		cityState: z.int().describe("The city-state's player id."),
		count: z.int().min(1).optional().describe("How many envoys, 1 when left out."),
	}), (playerID, { cityState, count }) => sendEnvoys(context.client, playerID, cityState, count));
	registerAction(server, context, "respond_to_deal", RESPOND_TO_DEAL, z.object({
		player: OTHER_PLAYER.describe("The player who proposed the deal, from in proposals."),
		accept: z.boolean(),
	}), (playerID, { player, accept }) => respondToDeal(context.client, playerID, player, accept));
	registerAction(server, context, "respond_to_session", RESPOND_TO_SESSION, z.object({
		player: OTHER_PLAYER.describe("The player with the session open, from in sessions."),
		option: z.string().describe("An option's key, such as CHOICE_POSITIVE or CHOICE_EXIT."),
	}), (playerID, { player, option }) => respondToSession(context.client, playerID, player, option));
	registerAction(server, context, "declare_war", DECLARE_WAR, z.object({ player: OTHER_PLAYER }), (playerID, { player }) => declareWar(context.client, playerID, player));
	registerAction(server, context, "propose_peace", PROPOSE_PEACE, z.object({ player: OTHER_PLAYER }), (playerID, { player }) => proposePeace(context.client, playerID, player));
}
