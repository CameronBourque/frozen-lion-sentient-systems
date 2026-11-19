// Registers an action tool: it runs the action for the server's player with a
// required reason, logs both at the decisions level, and returns the result.
// docs/design/core/mcp-server.md has the design.

import type { CallToolResult, McpServer, ToolCallback } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { ActionResult } from "../actions/actions.js";
import type { Position } from "../schemas.js";
import type { ToolContext } from "./context.js";
import { errorResult, forPlayer, textResult } from "./results.js";

// An ok result means the game took the request, not that it is done, so the
// model checks the state for the effect.
export const TOOK_REQUEST = "The game took the request.";

// The narrator panel shows the reason, so it is one short sentence.
// docs/design/agents/narration-and-messaging.md has the panel.
export const REASON_MAX_LENGTH = 200;

// Every action tool takes it. docs/tech-debt/optional-reason.md would make it
// optional here.
const REASON = z.string().min(1).max(REASON_MAX_LENGTH).describe(
	"One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it.",
);

export function actionResult(result: ActionResult): CallToolResult {
	return result.ok ? textResult(TOOK_REQUEST) : errorResult(result.reason);
}

// Returns the tile from an action's optional x and y, no tile when both are
// left out, or a failure when only one is given.
export function optionalTile(x: number | undefined, y: number | undefined): { tile?: Position } | { ok: false; reason: string } {
	if (x === undefined || y === undefined) {
		return x === y ? {} : { ok: false, reason: "Give both x and y, or neither." };
	}

	return { tile: { x, y } };
}

// Every action tool goes through here, so the reason and its log line are in
// one place. The reason comes first in the schema, so a model gives it before
// the action's own fields.
export function registerAction<Input extends z.ZodObject>(
	server: McpServer,
	{ client, player, logger }: ToolContext,
	name: string,
	description: string,
	inputSchema: Input,
	run: (playerID: number, args: z.infer<Input>) => Promise<ActionResult>,
): void {
	const schema = z.object({ reason: REASON, ...inputSchema.shape });
	const handle = ({ reason, ...args }: z.infer<typeof schema>): Promise<CallToolResult> => forPlayer(client, player, async (playerID) => {
		// The schema is the action's own fields with the reason, so the rest
		// are the action's fields.
		const result = await run(playerID, args as z.infer<Input>);

		logger.decision("action", `${name}: ${reason}`, { tool: name, player: playerID, reason, args, ok: result.ok, ...(result.ok ? {} : { failure: result.reason }) });

		return actionResult(result);
	});

	// The SDK's callback type depends on the schema, which TypeScript can't
	// resolve for a generic Input.
	server.registerTool(name, { description, inputSchema: schema }, handle as ToolCallback<typeof schema>);
}
