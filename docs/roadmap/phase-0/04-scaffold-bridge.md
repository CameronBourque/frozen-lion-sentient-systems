# Step 4: Scaffold the bridge project

Set up the TypeScript project in `packages/core/bridge/` so it runs in dev and compiles. Part of [phase 0](README.md).

## Tasks

1. `package.json` already exists. Add `"type": "module"`, plus `"engines": { "node": ">=22" }` to match CI.
2. Install dev dependencies: `typescript`, `tsx`, `@types/node`. Commit `package-lock.json`, because CI runs `npm ci`.
3. Add a `tsconfig.json` with `target ES2022`, `module NodeNext`, `strict true`, and `outDir build`.
4. Create the folders `src/`, `src/tuner/`, and `src/scripts/` (for throwaway gate scripts).
5. Add the scripts `"dev": "tsx src/main.ts"` and `"build": "tsc"`.
6. Check that `.gitignore` covers `node_modules/`, `build/`, and `dist/`.

## Done when

`npm run dev` prints a line and `npm run build` compiles.

## Record

The settled TypeScript conventions, in [rules/code.md](../../rules/code.md#conventions).
