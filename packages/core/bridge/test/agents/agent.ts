// Builds an agent for player 3, with tools that act on the test's fake game.

import type { Agent } from "../../src/agents/loop.js";
import type { Logger } from "../../src/log.js";
import type { ToolContext } from "../../src/mcp/context.js";
import { connectClient, toolDefinitions } from "../../src/mcp/in-process.js";
import { createServer } from "../../src/mcp/server.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { PLAYER_3 } from "../mcp/tools.js";

export const SYSTEM = "You play Civilization VI.";

export async function testAgent(client: TunerClient, logger: Logger, folder: string, first = false): Promise<Agent> {
	const toolContext: ToolContext = { client, player: PLAYER_3, memory: () => folder, logger };
	const tools = await connectClient(createServer(toolContext));

	return { playerID: 3, system: SYSTEM, tools, definitions: await toolDefinitions(tools), memoryFolder: folder, toolContext, first };
}
