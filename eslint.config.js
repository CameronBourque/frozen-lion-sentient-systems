// Lint rules for the repo's JavaScript. docs/rules/code.md describes the conventions
// these rules check.

import js from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin";
import globals from "globals";

export default [
	{ ignores: [".claude/", "coverage/", "**/build/", "**/dist/"] },

	js.configs.recommended,

	{
		files: ["**/*.{js,mjs}"],
		languageOptions: { globals: globals.node },
		plugins: { "@stylistic": stylistic },
		rules: {
			"@stylistic/indent": ["error", "tab"],
			"@stylistic/no-trailing-spaces": "error",
			"@stylistic/no-multiple-empty-lines": ["error", { max: 1 }],
			"@stylistic/padding-line-between-statements": [
				"error",
				// A blank line after a run of definitions, but not between them.
				{ blankLine: "always", prev: ["const", "let"], next: "*" },
				{ blankLine: "any", prev: ["const", "let"], next: ["const", "let"] },
				// A blank line before and after each block, such as if, for, and while.
				{ blankLine: "always", prev: "*", next: "block-like" },
				{ blankLine: "always", prev: "block-like", next: "*" },
				// A blank line before return. A return alone in its block has nothing before it.
				{ blankLine: "always", prev: "*", next: "return" },
			],
		},
	},
];
