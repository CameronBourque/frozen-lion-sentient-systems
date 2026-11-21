// Reads the knowledge files, from the executable's assets in a release and from
// the knowledge folder in development. docs/design/knowledge-files.md has the
// design.

import fs from "node:fs";
import path from "node:path";

// Each key is a file's path in the knowledge folder, with forward slashes.
export type Knowledge = ReadonlyMap<string, string>;

// The folder's name next to src/, and the start of each asset key, which
// scripts/build-exe.mjs writes.
export const KNOWLEDGE_FOLDER = "knowledge";

export function knowledgeFromFolder(folder: string): Knowledge {
	const files = fs.readdirSync(folder, { recursive: true, withFileTypes: true }).filter((entry) => entry.isFile());

	return new Map(files.map((entry) => {
		const file = path.join(entry.parentPath, entry.name);

		return [path.relative(folder, file).split(path.sep).join("/"), fs.readFileSync(file, "utf8")];
	}));
}

// The executable can hold other assets, so only keys in the folder count.
export function knowledgeFromAssets(keys: string[], read: (key: string) => string): Knowledge {
	const prefix = `${KNOWLEDGE_FOLDER}/`;

	return new Map(keys.filter((key) => key.startsWith(prefix)).map((key) => [key.slice(prefix.length), read(key)]));
}
