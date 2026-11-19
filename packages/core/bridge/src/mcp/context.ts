// What an MCP server's tools need: the game, and the player they act for.
// docs/design/core/mcp-server.md has the design.

import type { TunerClient } from "../tuner/client.js";
import type { PlayerSource } from "./player.js";

export interface ToolContext {
	client: TunerClient;
	player: PlayerSource;
}
