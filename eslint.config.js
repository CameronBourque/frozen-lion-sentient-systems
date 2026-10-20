// Lint rules for the repo's JavaScript and TypeScript. docs/rules/code.md describes the
// conventions these rules check.

import js from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin";
import globals from "globals";
import tseslint from "typescript-eslint";

// The same layout rules for JavaScript and TypeScript.
const stylisticRules = {
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
};

export default [
	{ ignores: [".claude/", "coverage/", "**/build/", "**/dist/"] },

	js.configs.recommended,

	{
		files: ["**/*.{js,mjs}"],
		languageOptions: { globals: globals.node },
		plugins: { "@stylistic": stylistic },
		rules: stylisticRules,
	},

	...tseslint.configs.recommended.map((config) => ({ ...config, files: ["**/*.ts"] })),

	{
		files: ["**/*.ts"],
		languageOptions: {
			globals: globals.node,
			// The promise and no-unsafe-* rules need type information from each package's tsconfig.json.
			parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
		},
		plugins: { "@stylistic": stylistic },
		rules: {
			...stylisticRules,
			// An unawaited promise fails silently in socket code.
			"@typescript-eslint/no-floating-promises": "error",
			"@typescript-eslint/no-misused-promises": "error",
			"@typescript-eslint/await-thenable": "error",
			"@typescript-eslint/require-await": "error",
			// Data typed any from the socket must get a checked type before code uses it.
			"@typescript-eslint/no-unsafe-argument": "error",
			"@typescript-eslint/no-unsafe-assignment": "error",
			"@typescript-eslint/no-unsafe-call": "error",
			"@typescript-eslint/no-unsafe-enum-comparison": "error",
			"@typescript-eslint/no-unsafe-member-access": "error",
			"@typescript-eslint/no-unsafe-return": "error",
			"@typescript-eslint/no-unsafe-unary-minus": "error",
			"@typescript-eslint/only-throw-error": "error",
			"@typescript-eslint/prefer-promise-reject-errors": "error",
		},
	},
];
