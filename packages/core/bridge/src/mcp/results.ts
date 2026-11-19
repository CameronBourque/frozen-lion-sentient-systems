// Turns a read from the core mod into an MCP tool result: compact JSON as
// text, or the error as a result marked isError, not a protocol error.
// docs/design/core/mcp-server.md has the design.

import type { CallToolResult } from "@modelcontextprotocol/server";
import type { StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";
import type { PlayerSource } from "./player.js";

type ReadResult = StashResult<unknown> | { ok: false; error: string };

// A request waits for the game while the bridge isn't connected, so a tool
// would never answer.
export const NOT_CONNECTED = "The bridge isn't connected to the game. Load a game with the tuner on, then try again";

export function toolResult(result: ReadResult): CallToolResult {
	return result.ok
		? { content: [{ type: "text", text: JSON.stringify(result.value) }] }
		: { content: [{ type: "text", text: result.error }], isError: true };
}

// Runs a read if the bridge is connected to the game.
export async function readFromGame(client: TunerClient, read: () => Promise<ReadResult>): Promise<CallToolResult> {
	return toolResult(client.isConnected ? await read() : { ok: false, error: NOT_CONNECTED });
}

// Runs a read for the server's player, or returns why there is no player.
export function readForPlayer(client: TunerClient, player: PlayerSource, read: (playerID: number) => Promise<ReadResult>): Promise<CallToolResult> {
	return readFromGame(client, async () => {
		const found = await player();

		return found.ok ? read(found.playerID) : found;
	});
}
