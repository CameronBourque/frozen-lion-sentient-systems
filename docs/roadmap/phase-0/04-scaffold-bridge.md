# Step 4: Scaffold the bridge project

Set up the TypeScript project in `packages/core/bridge/` so it runs in dev and compiles. Part of [phase 0](README.md).

## Tasks

1. `package.json` already exists. Add `"type": "module"`, plus `"engines": { "node": ">=22.13" }` to match the root `package.json`.
2. Install dev dependencies: `typescript`, `tsx`, `@types/node`. Commit `package-lock.json`, because CI runs `npm ci`.
3. Add a `tsconfig.json` with `target ES2022`, `module NodeNext`, `strict true`, and `outDir build`.
4. Create the folders `src/`, `src/tuner/`, and `src/scripts/` (for throwaway gate scripts).
5. Add the scripts `"dev": "tsx src/main.ts"` and `"build": "tsc"`.
6. Check that `.gitignore` covers `node_modules/`, `build/`, and `dist/`.
7. From the repo root, run `npm install --save-dev typescript-eslint`.
8. In the root `eslint.config.js`, add the `typescript-eslint` recommended config for `**/*.ts` files, with the same `@stylistic` rules as the JavaScript files.

The root Vitest setup runs the bridge's `*.test.ts` files, so the bridge needs no test runner of its own.

## Done when

`npm run dev` prints a line, and `npm run build` compiles. From the repo root, `npm run lint` and `npm test` pass.

## Record

The settled TypeScript conventions, in [rules/code.md](../../rules/code.md#conventions).
