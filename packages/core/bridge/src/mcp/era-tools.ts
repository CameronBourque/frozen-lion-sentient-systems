// The MCP tools for a new era: its dedications. Each description is written
// for the model. docs/design/core/mod/actions/dedications.md has the action.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { chooseDedications } from "../actions/dedications.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const CHOOSE_DEDICATIONS = `Make the dedications of the era that began, as the dedication popup's confirm does. Each is the type of one of get_choices' dedications.options, such as COMMEMORATION_SCIENTIFIC.

Give as many as dedications.picks: 1, or 3 in a heroic age. A refusal names the dedications offered.`;

export function registerEraTools(server: McpServer, context: ToolContext): void {
	registerAction(server, context, "choose_dedications", CHOOSE_DEDICATIONS, z.object({
		dedications: z.array(z.string()).describe("The dedications' types, as many as the picks."),
	}), (playerID, { dedications }) => chooseDedications(context.client, playerID, dedications));
}
