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

export function textResult(text: string): CallToolResult {
	return { content: [{ type: "text", text }] };
}

export function errorResult(text: string): CallToolResult {
	return { ...textResult(text), isError: true };
}

export function toolResult(result: ReadResult): CallToolResult {
	return result.ok ? textResult(JSON.stringify(result.value)) : errorResult(result.error);
}

// Runs a read if the bridge is connected to the game.
export async function readFromGame(client: TunerClient, read: () => Promise<ReadResult>): Promise<CallToolResult> {
	return client.isConnected ? toolResult(await read()) : errorResult(NOT_CONNECTED);
}

// Runs a tool for the server's player, or returns why it can't: the bridge
// isn't connected, or there is no player.
export async function forPlayer(client: TunerClient, player: PlayerSource, run: (playerID: number) => Promise<CallToolResult>): Promise<CallToolResult> {
	if (!client.isConnected) {
		return errorResult(NOT_CONNECTED);
	}

	const found = await player();

	return found.ok ? run(found.playerID) : errorResult(found.error);
}

// Runs a read for the server's player.
export function readForPlayer(client: TunerClient, player: PlayerSource, read: (playerID: number) => Promise<ReadResult>): Promise<CallToolResult> {
	return forPlayer(client, player, async (playerID) => toolResult(await read(playerID)));
}
