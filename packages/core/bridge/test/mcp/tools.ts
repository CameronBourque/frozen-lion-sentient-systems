// Test helpers for the MCP tools: a server connected to an in-process client,
// stash answers from the fake game, and a tool call's text.

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { Logger } from "../../src/log.js";
import type { PlayerSource } from "../../src/mcp/player.js";
import { createServer } from "../../src/mcp/server.js";
import type { TunerClient } from "../../src/tuner/client.js";
import type { FakeGame } from "../tuner/fake-game.js";

export const PLAYER_3: PlayerSource = () => Promise.resolve({ ok: true, playerID: 3 });

// Logs only errors, so the decision lines of the tests don't print.
export const QUIET = new Logger("error");

// Connects an in-process client to a server for the player.
export async function connectTools(tuner: TunerClient, player = PLAYER_3, logger = QUIET): Promise<Client> {
	const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
	const mcp = new Client({ name: "test", version: "1.0.0" });

	await createServer({ client: tuner, player, logger }).connect(serverSide);
	await mcp.connect(clientSide);

	return mcp;
}

// Answers the stash of each call in the table with its value as JSON. Other
// Lua prints nothing.
export function answerStash(game: FakeGame, values: Record<string, unknown>): void {
	let next: unknown;

	game.onCommand = (_stateIndex, lua) => {
		const call = /^SentientSystems_Stash\((.*)\)$/s.exec(lua)?.[1];

		if (call !== undefined && call in values) {
			next = values[call];

			return { output: ["1"] };
		}

		return lua === "SentientSystems_PrintPiece(1)" ? { output: [JSON.stringify(next)] } : {};
	};
}

// The tool's text, and whether it is an error.
export async function callTool(mcp: Client, name: string, args: Record<string, unknown> = {}): Promise<{ text: string; isError: boolean }> {
	const result = await mcp.callTool({ name, arguments: args });
	const [content] = result.content as { type: string; text: string }[];

	return { text: content.text, isError: result.isError === true };
}
