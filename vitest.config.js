import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
	test: {
		// .claude/ holds other sessions' worktrees, which have their own copies of the tests.
		exclude: [...configDefaults.exclude, ".claude/**"],
	},
});
