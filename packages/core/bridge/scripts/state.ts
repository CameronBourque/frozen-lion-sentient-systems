// Prints one player's state, choices, and trees as the agent will see them,
// with their sizes in bytes. Run it with `npm run state`, with a game loaded.
// Exits with code 1 if any can't be read.

import { readChoices } from "../src/choices/choices.js";
import { CORE_STATE } from "../src/connect.js";
import { formatSectionSizes, sectionSizes } from "../src/state/sizes.js";
import { readState } from "../src/state/state.js";
import { readCivicTree, readTechTree } from "../src/trees/research.js";
import { TunerClient } from "../src/tuner/client.js";

const client = new TunerClient({});

// Returns the player in the argument, or the local player, the human at the
// screen, or an error. See docs/findings/game-api.md.
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

// Reads the state, the choices, and the trees, and prints each with its size,
// or its error.
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
