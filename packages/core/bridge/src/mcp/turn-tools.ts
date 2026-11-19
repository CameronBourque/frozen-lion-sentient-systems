// The MCP tools for the turn itself: ending it. Each description is written
// for the model. docs/design/core/mod/actions/turn.md has the action.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { endTurn } from "../actions/turn.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const END_TURN = `End your turn, as the Next Turn button does. Call it when get_state's blockers.list and blockers.units are empty.

Without force, it fails while a blocker is left or a unit needs orders, and names each blocker with the choice that resolves it and the ids of those units. It fails while a diplomacy session is open, even with force, and for a second call in one turn.`;

export function registerTurnTools(server: McpServer, context: ToolContext): void {
	registerAction(server, context, "end_turn", END_TURN, z.object({
		force: z.boolean().optional().describe("End the turn anyway, skipping the blockers and the units that need orders. Use it only when a blocker has no tool."),
	}), (playerID, { force }) => endTurn(context.client, playerID, force));
}
