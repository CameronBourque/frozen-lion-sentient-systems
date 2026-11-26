// Test helpers for the MCP tools: a server connected to an in-process client,
// stash answers from the fake game, and a tool call's text.

import os from "node:os";
import path from "node:path";
import type { Client } from "@modelcontextprotocol/client";
import { Logger } from "../../src/log.js";
import type { MemorySource } from "../../src/mcp/context.js";
import { connectClient } from "../../src/mcp/in-process.js";
import type { PlayerSource } from "../../src/mcp/player.js";
import { createServer } from "../../src/mcp/server.js";
import type { TunerClient } from "../../src/tuner/client.js";
import type { FakeGame } from "../tuner/fake-game.js";

export const PLAYER_3: PlayerSource = () => Promise.resolve({ ok: true, playerID: 3 });

// Logs only errors, so the decision lines of the tests don't print.
export const QUIET = new Logger("error");

// A memory folder no test writes to. Tests of the memory tools pass their own.
const NO_MEMORY: MemorySource = () => path.join(os.tmpdir(), "no-memory");

// Connects an in-process client to a server for the player.
export function connectTools(tuner: TunerClient, player = PLAYER_3, logger = QUIET, memory = NO_MEMORY): Promise<Client> {
	return connectClient(createServer({ client: tuner, player, memory, logger }));
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
