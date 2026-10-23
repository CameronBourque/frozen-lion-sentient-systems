// Links the core mod into the game's user mods folder with a directory junction, or
// removes that link, and returns the lines to print and the exit code. A junction needs
// no administrator prompt.

import fs from "node:fs";
import path from "node:path";

export const MOD_NAME = "SentientSystemsCore";

// The game's folder under Documents. The game makes it on its first start.
export const gameFolder = (documents) => path.join(documents, "My Games", "Sid Meier's Civilization VI");

const linkPath = (documents) => path.join(gameFolder(documents), "Mods", MOD_NAME);

// Windows paths ignore case, so C:\Users and c:\users are the same folder.
export function samePath(a, b, platform = process.platform) {
	if (platform !== "win32") return path.resolve(a) === path.resolve(b);

	return path.win32.resolve(a).toLowerCase() === path.win32.resolve(b).toLowerCase();
}

export function linkMod({ documents, target }) {
	const game = gameFolder(documents);
	const link = linkPath(documents);

	// A missing game folder most likely means the wrong Documents folder, so don't guess.
	if (!fs.existsSync(game)) return { lines: [`${game} doesn't exist. Start the game once, then run this again.`], exitCode: 1 };

	// lstat sees the link itself, so a junction to a missing folder still counts. Node
	// reports a junction as a symbolic link.
	const stat = fs.lstatSync(link, { throwIfNoEntry: false });

	if (stat?.isSymbolicLink()) {
		const current = fs.readlinkSync(link);

		if (samePath(current, target)) return { lines: [`${link} already links to ${target}.`], exitCode: 0 };

		return { lines: [`${link} links to ${current}, not this checkout. Not changing it.`], exitCode: 1 };
	}

	if (stat) return { lines: [`${link} is a real folder, not a link. Not changing it.`], exitCode: 1 };

	// The game makes Mods only when you first add a mod.
	fs.mkdirSync(path.dirname(link), { recursive: true });
	fs.symlinkSync(target, link, "junction");

	return { lines: [`Linked ${link} to ${target}.`], exitCode: 0 };
}

// Removes only a link, so a real folder with someone's files in it is never deleted.
export function unlinkMod({ documents }) {
	const link = linkPath(documents);
	const stat = fs.lstatSync(link, { throwIfNoEntry: false });

	if (!stat) return { lines: [`${link} doesn't exist. Nothing to remove.`], exitCode: 0 };

	if (!stat.isSymbolicLink()) return { lines: [`${link} is a real folder, not a link. Not removing it.`], exitCode: 1 };

	// unlink removes the junction and leaves the folder it points at alone.
	fs.unlinkSync(link);

	return { lines: [`Removed ${link}.`], exitCode: 0 };
}
