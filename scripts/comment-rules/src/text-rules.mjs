// Comment rules that read only the text of a comment, so the Lua check and the
// ESLint rule for TypeScript share them. The rules are in docs/rules/code.md.

// One entry per rule. find gets the text of one comment and returns a message
// when it breaks the rule, or undefined when it doesn't.
export const TEXT_RULES = [
	{
		name: "line-number",
		// A game update moves line numbers, so a comment names the function.
		find(text) {
			const match = /\blines?\s+\d+/i.exec(text);

			if (match) return `comment names "${match[0]}"; name the function and its file instead`;
		},
	},
	{
		name: "json-shape",
		// The zod schemas hold the JSON shapes, so a comment links to one. An
		// object that opens with a quoted key, or a quoted key before a colon,
		// reads as a shape.
		find(text) {
			if (/\{\s*"|"[\w-]+"\s*:/.test(text)) return "comment holds a JSON shape; link to the zod schema instead";
		},
	},
];
