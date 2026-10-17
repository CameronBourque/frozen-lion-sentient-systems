import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
	test: {
		// .claude/ holds other sessions' worktrees, which have their own copies of the tests.
		exclude: [...configDefaults.exclude, ".claude/**"],
		coverage: {
			provider: "v8",
			include: ["scripts/**/src/**/*.mjs", "packages/**/src/**/*.{ts,mjs}"],
			// Each exception needs a reason.
			exclude: [
				// Only reads files and prints. Its logic is in run.mjs, which the tests cover.
				"scripts/check-docs/src/index.mjs",
			],
			// The table in the log, the same text as files for the CI job summary, and HTML for the report artifact.
			reporter: ["text", ["text", { file: "coverage.txt" }], ["text-summary", { file: "coverage-summary.txt" }], "html"],
			thresholds: { statements: 98, branches: 98, functions: 98, lines: 98 },
		},
	},
});
