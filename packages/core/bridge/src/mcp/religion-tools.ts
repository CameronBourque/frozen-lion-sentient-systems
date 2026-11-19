// The MCP tools that found a pantheon and a religion, and add a belief. Each
// description is written for the model.
// docs/design/core/mod/actions/religion.md has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { addBelief, foundPantheon, foundReligion } from "../actions/religion.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const FOUND_PANTHEON = `Found your pantheon with a belief, a type from get_choices' pantheon, such as BELIEF_RELIGIOUS_SETTLEMENTS, as the pantheon chooser's confirm does.

A refusal names the rule, such as a pantheon you have already or a belief another player took.`;

const FOUND_RELIGION = `Found your religion and add its beliefs, as the religion screen's confirm does. First a great prophet uses unit_action's found_religion on its Holy Site, which earns the belief picks. Then this tool picks the religion, its beliefs, and any name.

religion is a type from get_choices' religion.religions, such as RELIGION_BUDDHISM. beliefs are types from religion.beliefs, as many as religion.picks, with a follower belief first. Give name only for a religion whose customName is true.`;

const ADD_BELIEF = `Add one belief to your founded religion, a type from get_choices' religion.beliefs, which lists beliefs once the religion has a pick left. An apostle's evangelize_belief order earns a pick.`;

const BELIEF = z.string().describe("The belief's type, such as BELIEF_TITHE.");

export function registerReligionTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "found_pantheon", FOUND_PANTHEON, z.object({ belief: BELIEF }), (playerID, { belief }) => foundPantheon(client, playerID, belief));
	registerAction(server, context, "found_religion", FOUND_RELIGION, z.object({
		religion: z.string().describe("The religion's type, such as RELIGION_BUDDHISM."),
		beliefs: z.array(z.string()).describe("The beliefs' types, a follower belief first."),
		name: z.string().optional().describe("The religion's name, only when its customName is true."),
	}), (playerID, { religion, beliefs, name }) => foundReligion(client, playerID, religion, beliefs, name));
	registerAction(server, context, "add_belief", ADD_BELIEF, z.object({ belief: BELIEF }), (playerID, { belief }) => addBelief(client, playerID, belief));
}
