# Step 4: Scaffold the bridge project

Set up `packages/core/bridge/` as an npm workspace with TypeScript, so it runs in development, type-checks, and passes lint and tests. Part of [phase 0](README.md). The choices behind these tasks are in [rules/code.md](../../rules/code.md#typescript).

## Tasks

1. In the root `package.json`, add `"workspaces": ["packages/core/bridge"]`. The workspace shares the root `package-lock.json`, so the bridge gets no lockfile of its own.
2. In the bridge `package.json`, add `"type": "module"` and `"engines": { "node": ">=26" }`, to match the root.
3. From the repo root, install `typescript`, `tsx`, `@types/node`, and `typescript-eslint` as root dev dependencies. Commit the updated `package-lock.json`, because CI runs `npm ci`.
4. Add `packages/core/bridge/tsconfig.json` with `target ES2024`, `module NodeNext`, `strict true`, and `noEmit true`. Include `src/` and `test/`.
5. Add a `src/main.ts` that prints one line. Git doesn't keep empty folders, so `src/tuner/`, `src/scripts/` (for throwaway gate scripts), `test/`, and `test/tuner/` come with their first files in later steps.
6. `src/main.ts` only starts the program, so add it to the coverage `exclude` list in `vitest.config.js`, with the reason, as `scripts/check-docs/src/index.mjs` is.
7. Add the bridge scripts `"dev": "tsx src/main.ts"` and `"typecheck": "tsc"`. In the root `package.json`, add `"typecheck": "npm run typecheck --workspaces --if-present"`.
8. In the root `eslint.config.js`, add a block for `**/*.ts` files with the same `@stylistic` rules as the JavaScript files, plus the TypeScript rules in [rules/code.md](../../rules/code.md#typescript). Turn on `parserOptions.projectService`, because the promise and `no-unsafe-*` rules need type information.
9. In `.github/workflows/ci.yml`, add a `typecheck` job that runs `npm ci` and `npm run typecheck`, in the same form as the `lint` job.
10. In `.github/dependabot.yml`, merge the two npm entries into one for `/`, with `prefix: fix`, `prefix-development: chore`, and `include: scope`. The workspace has one lockfile, so one entry covers the bridge and the root.
11. Add `build/` and `dist/` to `.gitignore`. Step 5 writes to both.

After the PR merges, add `typecheck` to the required status checks in the `main` ruleset.

## Done when

`npm run dev --workspace packages/core/bridge` prints a line. From the repo root, `npm run lint`, `npm run typecheck`, and `npm run coverage` pass. An unawaited promise in a `.ts` file fails `npm run lint`.

## Record

If setting up the project changed any of the choices, update the TypeScript section of [rules/code.md](../../rules/code.md#typescript).
