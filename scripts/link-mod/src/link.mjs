// Links the core mod into the game's user mods folder with a directory junction, and
// returns the lines to print and the exit code. A junction needs no administrator prompt.

import fs from "node:fs";
import path from "node:path";

export const MOD_NAME = "SentientSystemsCore";

// The game's folder under Documents. The game makes it on its first start.
export const gameFolder = (documents) => path.join(documents, "My Games", "Sid Meier's Civilization VI");

export function linkMod({ documents, target }) {
	const game = gameFolder(documents);
	const mods = path.join(game, "Mods");
	const link = path.join(mods, MOD_NAME);

	// A missing game folder most likely means the wrong Documents folder, so don't guess.
	if (!fs.existsSync(game)) return { lines: [`${game} doesn't exist. Start the game once, then run this again.`], exitCode: 1 };

	// lstat sees the link itself, so a junction to a missing folder still counts.
	if (fs.lstatSync(link, { throwIfNoEntry: false })) return { lines: [`${link} already exists. Not changing it.`], exitCode: 1 };

	// The game makes Mods only when you first add a mod.
	fs.mkdirSync(mods, { recursive: true });
	fs.symlinkSync(target, link, "junction");

	return { lines: [`Linked ${link} to ${target}.`], exitCode: 0 };
}
