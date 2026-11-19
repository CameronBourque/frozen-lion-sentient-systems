// The MCP tools that change the government. Each description is written for
// the model. docs/design/core/mod/actions/government.md has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { setGovernment } from "../actions/policies.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SET_GOVERNMENT = `Change your government to a type from get_choices' governments, such as GOVERNMENT_AUTOCRACY, as the government screen's confirm does. A government with anarchy turns starts after them.

You can change it when governments.canChange is true. A refusal names the rule, such as a change made this turn already, or a turn with no civic completed, which points at the unlock when governments shows one.`;

export function registerGovernmentTools(server: McpServer, context: ToolContext): void {
	registerAction(server, context, "set_government", SET_GOVERNMENT, z.object({
		government: z.string().describe("The government's type, such as GOVERNMENT_AUTOCRACY."),
	}), (playerID, { government }) => setGovernment(context.client, playerID, government));
}
