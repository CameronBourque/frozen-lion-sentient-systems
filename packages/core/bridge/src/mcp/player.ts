// Where an MCP server's tools get the player they act for. The tools only call
// the source, so phase 3 can give each agent's server its own player.
// docs/design/core/mcp-server.md has the design.

import type { TunerClient } from "../tuner/client.js";
import { readGameNumber } from "./game-number.js";

export type PlayerResult =
	| { ok: true; playerID: number }
	| { ok: false; error: string };

export type PlayerSource = () => Promise<PlayerResult>;

// The human at the screen, asked for on each call, so a load of another save
// needs nothing more. In single player the agent plays the human slot.
// docs/findings/game-api.md has Game.GetLocalPlayer().
export function localPlayer(client: TunerClient): PlayerSource {
	return async () => {
		const read = await readGameNumber(client, "Game.GetLocalPlayer()", "player ID");

		return read.ok ? { ok: true, playerID: read.value } : read;
	};
}
