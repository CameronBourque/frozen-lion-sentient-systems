// Finds Lua patterns in the mods that use a character class, such as %a or %s.
// The game's Lua matches the classes by the Windows code page, so they split
// UTF-8 text. See docs/findings/lua/patterns.md.

// A line that passes a pattern to a string function, or names one.
const PATTERN_LINE = /\b(?:find|match|gmatch|gsub)\s*\(|\b\w*pattern\w*\s*=/i;
// A quoted string, with its escapes.
const STRING = /"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'/g;
// A class after an odd number of percent signs. "%%a" is a percent sign and an
// a, not a class.
const CLASS = /(?<!%)(?:%%)*%([acdlpsuwx])/i;

// Returns the class letters in the line's strings, if the line holds a pattern.
// A full-line comment holds none.
export function findClasses(line) {
	if (/^\s*--/.test(line) || !PATTERN_LINE.test(line)) return [];

	const classes = [];

	for (const match of line.matchAll(STRING)) {
		const found = (match[1] ?? match[2]).match(CLASS);

		if (found) classes.push(found[1]);
	}

	return classes;
}

// Returns one "file:line: message" per class in a pattern, and the exit code.
export function checkPatterns(files) {
	const lines = [];

	for (const [file, text] of Object.entries(files)) {
		text.split(/\r?\n/).forEach((line, index) => {
			for (const letter of findClasses(line)) {
				lines.push(`${file}:${index + 1}: %${letter} matches by the game's code page and splits UTF-8 text. Use a set from SENTIENTSYSTEMS_CHARS. See docs/findings/lua/patterns.md`);
			}
		});
	}

	return { lines, exitCode: lines.length > 0 ? 1 : 0 };
}
