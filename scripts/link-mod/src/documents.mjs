// Finds the user's Documents folder from the registry, so a Documents folder that
// OneDrive moved works too. index.mjs runs `reg query` and passes in its output.

import path from "node:path";

export const REGISTRY_KEY = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders";
export const REGISTRY_VALUE = "Personal";

// Matches the value's row in `reg query` output, such as
// "    Personal    REG_EXPAND_SZ    %USERPROFILE%\Documents".
const valueRow = new RegExp(`^\\s*${REGISTRY_VALUE}\\s+REG_(?:EXPAND_)?SZ\\s+(.+?)\\s*$`, "m");

// Returns the value's data, or null when the output has no such row.
export function parseRegQuery(output) {
	return output.match(valueRow)?.[1] ?? null;
}

// Replaces each %NAME% with its environment variable. The value is REG_EXPAND_SZ, so it
// can hold %USERPROFILE%. Windows names are case-insensitive, but a plain object's keys
// aren't, so the lookup ignores case. An unknown name stays as it is.
export function expandVariables(value, env) {
	const names = new Map(Object.keys(env).map((name) => [name.toUpperCase(), name]));

	return value.replace(/%([^%]+)%/g, (match, name) => {
		const key = names.get(name.toUpperCase());

		return key === undefined ? match : env[key];
	});
}

// Returns the Documents folder and any warnings. When the registry can't be read, it
// warns and falls back to Documents in the home folder.
export function findDocuments({ readRegistry, env, homedir }) {
	const fallback = path.join(homedir, "Documents");
	let output;

	try {
		output = readRegistry();
	} catch (error) {
		return { documents: fallback, warnings: [`Couldn't read the registry (${error.message}). Using ${fallback}.`] };
	}

	const value = parseRegQuery(output);

	if (value === null) return { documents: fallback, warnings: [`The registry has no ${REGISTRY_VALUE} value. Using ${fallback}.`] };

	return { documents: expandVariables(value, env), warnings: [] };
}
