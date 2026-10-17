// Check 5: warn, without failing, on files over 150 lines.

import { problem } from "./parse.mjs";

export const MAX_LINES = 150;

export function checkLength(repo) {
	return [...repo.docs.values()]
		.filter((doc) => doc.lines.length > MAX_LINES)
		.map((doc) => ({
			...problem(doc.path, MAX_LINES + 1, "length", `${doc.lines.length} lines. Aim for under ${MAX_LINES}`),
			warning: true,
		}));
}
