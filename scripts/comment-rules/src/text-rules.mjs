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
];
