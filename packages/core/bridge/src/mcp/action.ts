// Registers an action tool: it runs the action for the server's player and
// returns that the game took the request, or the action's reason as an error
// result. docs/design/core/mcp-server.md has the design.

import type { CallToolResult, McpServer, ToolCallback } from "@modelcontextprotocol/server";
import type { z } from "zod";
import type { ActionResult } from "../actions/actions.js";
import type { ToolContext } from "./context.js";
import { errorResult, forPlayer, textResult } from "./results.js";

// An ok result means the game took the request, not that it is done, so the
// model checks the state for the effect.
export const TOOK_REQUEST = "The game took the request.";

export function actionResult(result: ActionResult): CallToolResult {
	return result.ok ? textResult(TOOK_REQUEST) : errorResult(result.reason);
}

// Every action tool goes through here, so a field that every action has, such
// as the reason, is added in one place.
export function registerAction<Input extends z.ZodObject>(
	server: McpServer,
	{ client, player }: ToolContext,
	name: string,
	description: string,
	inputSchema: Input,
	run: (playerID: number, args: z.infer<Input>) => Promise<ActionResult>,
): void {
	const handle = (args: z.infer<Input>): Promise<CallToolResult> => forPlayer(client, player, async (playerID) => actionResult(await run(playerID, args)));

	// The SDK's callback type depends on the schema, which TypeScript can't
	// resolve for a generic Input.
	server.registerTool(name, { description, inputSchema }, handle as ToolCallback<Input>);
}
