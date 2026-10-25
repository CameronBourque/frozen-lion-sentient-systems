// Prints one player's state from the running game, as the agent will see it, and its size in bytes.
// Run it with `npm run state`, with a game loaded. It reads the local player's state. An argument
// such as `npm run state -- 1` reads another player's. In PowerShell, write the `--` as `'--'`, as
// docs/rules/code.md says. It exits with code 1 if the state can't be read.

import { CORE_STATE } from "../src/connect.js";
import { readState, type StateResult } from "../src/state/state.js";
import { TunerClient } from "../src/tuner/client.js";

const client = new TunerClient({});

// Reads the state of the player in the argument, or of the local player, the human at the screen.
// See docs/findings/game-api.md.
async function read(): Promise<{ playerID: number; result: StateResult }> {
	const argument = process.argv[2];
	let playerID: number;

	try {
		playerID = argument === undefined
			? Number((await client.run(CORE_STATE, "print(Game.GetLocalPlayer())")).lines[0])
			: Number(argument);
	} catch (error) {
		return { playerID: -1, result: { ok: false, error: `Asking for the local player failed: ${(error as Error).message}` } };
	}

	return { playerID, result: await readState(client, playerID) };
}

console.error("Waiting for the game's tuner...");
client.connect();

const { playerID, result } = await read();

client.close();

if (result.ok) {
	console.log(JSON.stringify(result.state, null, 2));
	console.error(`Player ${playerID}'s state is ${result.bytes} bytes.`);
} else {
	console.error(result.error);
	process.exitCode = 1;
}
