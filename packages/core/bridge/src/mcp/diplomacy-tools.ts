// The MCP tools that deal with other players: envoys to city-states. Each
// description is written for the model.
// docs/design/core/mod/actions/envoys.md has the action.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { sendEnvoys } from "../actions/envoys.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SEND_ENVOYS = `Send envoys to a city-state, a player id from get_choices' envoys.cityStates, as the City-States screen does. count is 1 when left out, and at most envoys.tokens.

The envoy blocker stays up until you send every envoy. To keep some for later, end the turn with force.`;

export function registerDiplomacyTools(server: McpServer, context: ToolContext): void {
	registerAction(server, context, "send_envoys", SEND_ENVOYS, z.object({
		cityState: z.int().describe("The city-state's player id."),
		count: z.int().min(1).optional().describe("How many envoys, 1 when left out."),
	}), (playerID, { cityState, count }) => sendEnvoys(context.client, playerID, cityState, count));
}
