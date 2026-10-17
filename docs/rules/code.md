# Code rules

Rules for code in every package. Each architecture rule links to the design decision that explains it.

## Architecture

- [Only core talks to the game. Feature mods use the core API and never call FireTuner or game Lua directly](../design/architecture.md#core-boundary).
- [Move code into core only when a second mod needs it](../design/architecture.md#core-boundary).
- [Actions go through the game's own request functions, so the game checks legality](../design/core/in-game-lua.md).
- [Agent state comes from the player's visibility data, never from the screen](../design/core/in-game-lua.md#decisions).
- [Every failed action returns a reason](../design/core/in-game-lua.md#decisions).
- [Every action tool has a required `reason` field](../design/agents/narration-and-messaging.md#narrator-panel).
- [The API key never goes into a game setup parameter](../design/core/bridge.md).
- [A file format change bumps that file's schema version and ships a migration](../design/versioning.md#bump-rules).

## Conventions

These conventions come from `scripts/check-docs/`, the first code in the repo. Expect them to change as the bridge and the mods add code.

- **Use the standard library before a dependency.** Add a package only when the standard library can't do the job. Dev tools, such as the linter and the test runner, live in the root `package.json`.
- **One file per concern.** Start each file with a comment that says what it does. An entry file reads the input, prints the output, and calls the other files.
- **Keep logic apart from input and output.** Functions take data and return results, so tests can pass in data without files or a network.
- **Put rules in tables.** When code applies a list of similar rules, write each rule as one entry with a name, an example, and its logic. Then loop over the table.
- **Name the parts of a long regex.** Build it from named strings, and comment it with an example that it matches.
- **Split a line only when it helps.** Break up a line that does several steps. Keep a short chain that reads top to bottom, and comment it.
- **Comment the reason, not the action.** Say why a line exists or which case it handles.

## Lint and test

- `npm run lint` runs ESLint with the rules in `eslint.config.js`. It checks tabs, trailing spaces, and blank lines: one after a run of definitions, one before and after each block, and one before `return`.
- `npm test` runs Vitest. Name a test file `*.test.mjs` or `*.test.ts`, and put it next to the file it tests. Give each rule a case that it catches and a case that it lets through.
- `npm run coverage` runs the tests and measures coverage. Statements, branches, functions, and lines must each stay at 98% or more, or the run fails. To leave a file out, add it to the coverage `exclude` list in `vitest.config.js` with a comment that gives the reason.
- The CI `test` job runs `npm run coverage`. It puts the coverage table in the job summary and uploads the HTML report as the `coverage-report` artifact.
- CI runs lint and test as separate jobs in `.github/workflows/ci.yml`, plus an `actionlint` job that checks the workflow files. Lint and test need Node 22.13 or later. `.nvmrc` sets the Node version for CI.
- Phase 0 [step 4](../roadmap/phase-0/04-scaffold-bridge.md) adds TypeScript linting when it sets up the bridge.
- Lua code needs its own test runner. Pick one when the core mod gets tests.
