// The MCP tools for spies: missions, travel, and an escape's route. Each
// description is written for the model.
// docs/design/core/mod/actions/cities.md has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { chooseEscapeRoute, spyMission, spyTravel } from "../actions/spies.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SPY_MISSION = `Start a mission in the city a spy stands in, the type of one of its missions in get_choices' spyMissions, such as UNITOPERATION_SPY_SIPHON_FUNDS. A counterspy mission also takes the district to guard, such as DISTRICT_CAMPUS.

Ok means the mission has begun, not that it has finished. A refusal lists the missions the spy can start, or the game's reasons for a disabled one.`;

const SPY_TRAVEL = `Send a spy to a city from its destinations in get_choices' spyMissions, named by the city's owner and id. Ok means the spy has set out, not that it has arrived.`;

const CHOOSE_ESCAPE_ROUTE = `Choose how your escaping spy leaves its city, the type of one of its routes in get_choices' spies, such as DISTRICT_HARBOR. The game offers one escaping spy at a time, so the route names no spy.

Ok means the game took the route, not that the spy got away. A route with blocked can't be taken.`;

const SPY_ID = z.int().describe("The spy's unit id, from spyMissions.");

export function registerEspionageTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "spy_mission", SPY_MISSION, z.object({
		unitID: SPY_ID,
		mission: z.string().describe("The mission's type, such as UNITOPERATION_SPY_SIPHON_FUNDS."),
		district: z.string().optional().describe("For a counterspy mission, the district to guard."),
	}), (playerID, { unitID, mission, district }) => spyMission(client, playerID, unitID, mission, district));
	registerAction(server, context, "spy_travel", SPY_TRAVEL, z.object({
		unitID: SPY_ID,
		owner: z.int().describe("The destination city's owner."),
		cityID: z.int().describe("The destination city's id."),
	}), (playerID, { unitID, owner, cityID }) => spyTravel(client, playerID, unitID, owner, cityID));
	registerAction(server, context, "choose_escape_route", CHOOSE_ESCAPE_ROUTE, z.object({
		route: z.string().describe("The route's type, such as DISTRICT_HARBOR."),
	}), (playerID, { route }) => chooseEscapeRoute(client, playerID, route));
}
