// Finds full-line Lua comments over the column limit in docs/rules/code.md.
// ESLint checks the TypeScript and JavaScript comments, and the CI lint job has
// no Lua tool, so this covers the Lua ones.

// The same limit as the comments option of max-len in eslint.config.js.
export const LIMIT = 80;
// The same tab width as the tabWidth option of max-len.
const TAB_WIDTH = 4;

// Returns the width of a line in columns. A tab counts as TAB_WIDTH and a
// character as 1, however many bytes it takes.
export function width(line) {
	return [...line.replaceAll("\t", " ".repeat(TAB_WIDTH))].length;
}

// Returns one "file:line: message" per full-line comment over the limit, and
// the exit code. A comment after code on the same line isn't checked.
export function checkComments(files, limit = LIMIT) {
	const lines = [];

	for (const [file, text] of Object.entries(files)) {
		text.split(/\r?\n/).forEach((line, index) => {
			const columns = width(line);

			if (/^\s*--/.test(line) && columns > limit) {
				lines.push(`${file}:${index + 1}: comment is ${columns} columns, over ${limit}`);
			}
		});
	}

	return { lines, exitCode: lines.length > 0 ? 1 : 0 };
}
