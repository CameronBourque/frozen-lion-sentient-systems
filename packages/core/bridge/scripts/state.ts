// Prints one player's state, choices, and trees as the agent will see them,
// with their sizes in bytes. Run it with `npm run state`, with a game loaded.
// Exits with code 1 if any can't be read.

import { readChoices } from "../src/choices/choices.js";
import { localPlayer, type PlayerResult } from "../src/mcp/player.js";
import { formatSectionSizes, sectionSizes } from "../src/state/sizes.js";
import { readState } from "../src/state/state.js";
import { readCivicTree, readTechTree } from "../src/trees/research.js";
import { TunerClient } from "../src/tuner/client.js";

const client = new TunerClient({});

// Returns the player in the argument, or the local player, the human at the
// screen, or an error.
function pickPlayer(): Promise<PlayerResult> {
	const argument = process.argv[2];

	return argument === undefined ? localPlayer(client)() : Promise.resolve({ ok: true, playerID: Number(argument) });
}

// Reads the state, the choices, and the trees, and prints each with its size,
// or its error.
async function main(): Promise<void> {
	const player = await pickPlayer();

	if (!player.ok) {
		console.error(player.error);
		process.exitCode = 1;

		return;
	}

	const { playerID } = player;
	const state = await readState(client, playerID);

	if (state.ok) {
		console.log(JSON.stringify(state.value, null, 2));
		console.error(`Player ${playerID}'s state is ${state.bytes} bytes:`);
		console.error(formatSectionSizes(sectionSizes(state.value, state.bytes)));
	} else {
		console.error(state.error);
		process.exitCode = 1;
	}

	const choices = await readChoices(client, playerID);

	if (choices.ok) {
		console.log(JSON.stringify(choices.value, null, 2));
		console.error(`Player ${playerID}'s choices are ${choices.bytes} bytes:`);
		console.error(formatSectionSizes(sectionSizes(choices.value, choices.bytes)));
	} else {
		console.error(choices.error);
		process.exitCode = 1;
	}

	for (const [name, read] of [["tech tree", readTechTree], ["civic tree", readCivicTree]] as const) {
		const tree = await read(client, playerID);

		if (tree.ok) {
			console.log(JSON.stringify(tree.value, null, 2));
			console.error(`Player ${playerID}'s ${name} is ${tree.bytes} bytes.`);
		} else {
			console.error(tree.error);
			process.exitCode = 1;
		}
	}
}

console.error("Waiting for the game's tuner...");
client.connect();

await main();

client.close();
