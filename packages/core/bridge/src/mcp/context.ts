// What an MCP server's tools need: the game, the player they act for, and the
// log that records each action.
// docs/design/core/mcp-server.md has the design.

import type { Logger } from "../log.js";
import type { TunerClient } from "../tuner/client.js";
import type { PlayerSource } from "./player.js";

export interface ToolContext {
	client: TunerClient;
	player: PlayerSource;
	logger: Logger;
}
