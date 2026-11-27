// What an MCP server's tools need: the game, the player they act for, where
// that player's memory lives, and the log that records each action.
// docs/design/core/mcp-server.md has the design.

import type { Logger } from "../log.js";
import type { TunerClient } from "../tuner/client.js";
import type { PlayerSource } from "./player.js";

// Returns the player's memory folder. Phase 4 can return a restored snapshot.
export type MemorySource = (playerID: number) => string;

export interface ToolContext {
	client: TunerClient;
	player: PlayerSource;
	memory: MemorySource;
	logger: Logger;
}
