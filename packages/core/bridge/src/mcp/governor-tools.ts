// The MCP tools on the Governors panel: appoint, promote, and assign. They
// need Rise and Fall. Each description is written for the model.
// docs/design/core/mod/actions/governors.md has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { appointGovernor, assignGovernor, promoteGovernor } from "../actions/governors.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const APPOINT_GOVERNOR = `Spend a governor title to appoint a governor from get_choices' governors.appoint, such as GOVERNOR_THE_DEFENDER. governors.appoint is there only with a title to spend.`;

const PROMOTE_GOVERNOR = `Spend a governor title on a promotion for an appointed governor, from get_choices' governors.promote, which lists the promotions each can earn now.`;

const ASSIGN_GOVERNOR = `Send an appointed governor to a city from get_choices' governors.assign, by the city's owner and id. The same call places a governor with no city and moves one to another city.

governors.assign lists your cities, then for an Ambassador the city-states you have met, then for a governor that can go abroad the capitals of the players you have met. A city the panel turns off lists the game's reasons as blocked.`;

const GOVERNOR = z.string().describe("The governor's type, such as GOVERNOR_THE_DEFENDER.");

export function registerGovernorTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "appoint_governor", APPOINT_GOVERNOR, z.object({ governor: GOVERNOR }), (playerID, { governor }) => appointGovernor(client, playerID, governor));
	registerAction(server, context, "promote_governor", PROMOTE_GOVERNOR, z.object({
		governor: GOVERNOR,
		promotion: z.string().describe("The promotion's type, from governors.promote."),
	}), (playerID, { governor, promotion }) => promoteGovernor(client, playerID, governor, promotion));
	registerAction(server, context, "assign_governor", ASSIGN_GOVERNOR, z.object({
		governor: GOVERNOR,
		owner: z.int().describe("The city's owner, from governors.assign."),
		cityID: z.int().describe("The city's id, from governors.assign."),
	}), (playerID, { governor, owner, cityID }) => assignGovernor(client, playerID, governor, owner, cityID));
}
