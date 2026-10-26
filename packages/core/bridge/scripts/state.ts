// Prints one player's state, choices, and tech tree from the running game, as the agent will see
// them, and their sizes in bytes. Run it with `npm run state`, with a game loaded. It reads the local
// player's. An argument such as `npm run state -- 1` reads another player's. In PowerShell, write the
// `--` as `'--'`, as docs/rules/code.md says. It exits with code 1 if any of them can't be read.

import { readChoices } from "../src/choices/choices.js";
import { CORE_STATE } from "../src/connect.js";
import { readState } from "../src/state/state.js";
import { readTechTree } from "../src/trees/trees.js";
import { TunerClient } from "../src/tuner/client.js";

const client = new TunerClient({});

// Returns the player in the argument, or the local player, the human at the screen, or an error.
// See docs/findings/game-api.md.
async function pickPlayer(): Promise<{ playerID: number } | { error: string }> {
	const argument = process.argv[2];

	if (argument !== undefined) {
		return { playerID: Number(argument) };
	}

	try {
		return { playerID: Number((await client.run(CORE_STATE, "print(Game.GetLocalPlayer())")).lines[0]) };
	} catch (error) {
		return { error: `Asking for the local player failed: ${(error as Error).message}` };
	}
}

// Reads the state, the choices, and the tech tree, and prints each with its size, or its error.
async function main(): Promise<void> {
	const player = await pickPlayer();

	if ("error" in player) {
		console.error(player.error);
		process.exitCode = 1;

		return;
	}

	const { playerID } = player;
	const state = await readState(client, playerID);

	if (state.ok) {
		console.log(JSON.stringify(state.state, null, 2));
		console.error(`Player ${playerID}'s state is ${state.bytes} bytes.`);
	} else {
		console.error(state.error);
		process.exitCode = 1;
	}

	const choices = await readChoices(client, playerID);

	if (choices.ok) {
		console.log(JSON.stringify(choices.choices, null, 2));
		console.error(`Player ${playerID}'s choices are ${choices.bytes} bytes.`);
	} else {
		console.error(choices.error);
		process.exitCode = 1;
	}

	const techTree = await readTechTree(client, playerID);

	if (techTree.ok) {
		console.log(JSON.stringify(techTree.tree, null, 2));
		console.error(`Player ${playerID}'s tech tree is ${techTree.bytes} bytes.`);
	} else {
		console.error(techTree.error);
		process.exitCode = 1;
	}
}

console.error("Waiting for the game's tuner...");
client.connect();

await main();

client.close();
