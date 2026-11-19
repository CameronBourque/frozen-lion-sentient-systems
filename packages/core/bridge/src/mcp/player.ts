// Where an MCP server's tools get the player they act for. The tools only call
// the source, so phase 3 can give each agent's server its own player.
// docs/design/core/mcp-server.md has the design.

import { CORE_STATE } from "../connect.js";
import { explainFailure } from "../errors.js";
import type { TunerClient } from "../tuner/client.js";

export type PlayerResult =
	| { ok: true; playerID: number }
	| { ok: false; error: string };

export type PlayerSource = () => Promise<PlayerResult>;

// The human at the screen, asked for on each call, so a load of another save
// needs nothing more. In single player the agent plays the human slot.
// docs/findings/game-api.md has Game.GetLocalPlayer().
export function localPlayer(client: TunerClient): PlayerSource {
	return async () => {
		let lines: string[];

		try {
			({ lines } = await client.run(CORE_STATE, "print(Game.GetLocalPlayer())"));
		} catch (error) {
			return { ok: false, error: explainFailure(error, "local player request") };
		}

		const playerID = Number(lines[0]);

		return lines.length === 1 && Number.isInteger(playerID) && playerID >= 0
			? { ok: true, playerID }
			: { ok: false, error: `Game.GetLocalPlayer() printed ${JSON.stringify(lines)}, not a player ID` };
	};
}
