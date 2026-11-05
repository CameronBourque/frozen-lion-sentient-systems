# Code rules

Rules for code in every package. Each architecture rule links to the design decision that explains it.

## Architecture

- [Only core talks to the game. Feature mods use the core API and never call FireTuner or game Lua directly](../design/architecture.md#core-boundary).
- [Move code into core only when a second mod needs it](../design/architecture.md#core-boundary).
- [Actions go through the game's own request functions, so the game checks legality](../design/core/mod/actions.md).
- [Agent state comes from the player's visibility data, never from the screen](../design/core/mod/state.md#decisions).
- [Every failed action returns a reason](../design/core/mod/actions.md#decisions).
- [Every action tool has a required `reason` field](../design/agents/narration-and-messaging.md#narrator-panel).
- [The API key never goes into a game setup parameter](../design/core/settings.md).
- [A file format change bumps that file's schema version and ships a migration](../design/versioning.md#bump-rules).

## Conventions

These conventions come from `scripts/check-docs/`, the first code in the repo. Expect them to change as the bridge and the mods add code.

- **Use the standard library before a dependency.** Add a package only when the standard library can't do the job. Dev tools, such as the linter and the test runner, live in the root `package.json`.
- **One file per concern.** Start each file with a short comment on its purpose. An entry file reads the input, prints the output, and calls the other files.
- **Keep logic apart from input and output.** Functions take data and return results, so tests can pass in data without files or a network.
- **Put rules in tables.** When code applies a list of similar rules, write each rule as one entry with a name, an example, and its logic. Then loop over the table.
- **Name the parts of a long regex.** Build it from named strings, and test it with examples that it matches.
- **Split a line only when it helps.** Break up a line that does several steps. Keep a short chain that reads top to bottom, and comment it.

## Comments

Most code should read without comments. Name things so they explain themselves.

- **Start each file with a short comment on its purpose.** One to three lines.
- **Comment the reason, not the action.** Say why a line exists or which case it handles, such as a quirk of a game call. Keep it to a line or two.
- **Don't say what a function does when its name and signature do.** Comment a function only when it is hard to read, or when it has a reason or a case that the code doesn't show.
- **Put each comment where its subject is.** When a function needs a comment, put it above the function and describe the whole function. A comment about one step goes on the line before that step.
- **Keep data shapes out of comments.** This includes the fields that a test fake reads from its data. The zod schemas in `packages/core/bridge/src/` are the home of the core mod's JSON shapes. Give a field a `.describe()` note when its name doesn't say what it means, such as how it is rounded or which screen it matches. Link to the schema from the code.
- **Keep examples out of comments.** Write them as tests.
- **Name the game's function, not its line numbers.** When code copies a game function, name the function and its file. Line numbers go stale when the game updates, and the name still finds the code.
- **Don't repeat a document.** Link to it instead.
- **Keep comment lines to 80 characters or fewer.**

## TypeScript

The bridge's TypeScript setup. Why each choice was made is in [design/core/toolchain.md](../design/core/toolchain.md#decisions).

- **Node 26.** `.nvmrc` and the `engines` fields set it, and the bridge executable ships with it. Node 26 is an LTS release, supported until 2029-04-30. Move the repo to the next LTS release before then, so the executable never ships a runtime without security fixes.
- **`tsx` runs TypeScript in development.** TypeScript features that need more than removing types, such as enums, are allowed.
- **Pass a script's arguments after `--`.** Write `npm run state -- 1` in docs and comments. In PowerShell, write the `--` as `'--'`: `npm run state '--' 1`. On Windows, `npm` in PowerShell is the script `npm.ps1`, and PowerShell drops a bare `--` before it calls a script. npm then reads the arguments as its own settings, and the script never gets them. cmd keeps the quotes, so it needs the bare `--`.
- **`tsc` only type-checks.** `npm run typecheck` runs it with `noEmit`, as its own CI job. esbuild bundles the release, so nothing uses compiled output.
- **TypeScript 6 loads no `@types` packages by default.** The bridge `tsconfig.json` lists `"types": ["node"]`. Add a package there when its types are needed.
- **ES modules, with no namespaces.** Group code by file, and import what each file needs. `declare namespace` in a `.d.ts` file is still allowed, to describe a library's types.
- **Lint rules.** `.ts` files use typescript-eslint's `recommended` rules, plus these rules that need type information:
  - promises: `no-floating-promises`, `no-misused-promises`, `await-thenable`, and `require-await`,
  - values typed `any`: `no-unsafe-argument`, `no-unsafe-assignment`, `no-unsafe-call`, `no-unsafe-enum-comparison`, `no-unsafe-member-access`, `no-unsafe-return`, and `no-unsafe-unary-minus`,
  - errors: `only-throw-error` and `prefer-promise-reject-errors`.

## Lint and test

- `npm run lint` runs ESLint with the rules in `eslint.config.js`. It checks tabs, trailing spaces, and blank lines: one after a run of definitions, one before and after each block, and one before `return`. It also runs `scripts/lua-comments/`, which fails on a full-line Lua comment over 80 columns, counting a tab as 4 and a character as 1. ESLint can't read Lua, and the CI `lint` job has no Lua tool.
- Lint also checks these [comment rules](#comments), in Lua and in TypeScript, from the shared code in `scripts/comment-rules/`. A broken rule fails the build.
  - A file header over three lines. The header is the first comment before any code, up to the first blank line.
  - A line number, such as "line 12" or "lines 3 to 5".
  - "such as", "for example", or "for instance" followed by a quoted or code example.
  - A JSON shape: `{` followed by a quote, or a quoted key before a colon.
  - These are heuristics, so a comment can opt out of the last three by holding `comment-lint-ignore:` and a short reason. A marker with no reason skips nothing, and it covers only its own comment line. The header and line width checks have no opt-out.
  - A path to a doc that doesn't exist, or a path with a `*` whose file does exist, as [docs.md](docs.md#structure) describes. It has no opt-out, because a doc that isn't written yet takes a `*`. `scripts/yml-comments/` runs it on yml comments, because ESLint can't read yml.
  - Lint can't see a comment that restates the next line of code, or a data shape written as prose. Those stay with review.
- `npm test` runs Vitest. Put code in a `src/` folder and tests in a `test/` folder beside it, in each package and script folder. `test/` mirrors `src/`, so the tests for `src/tuner/framing.ts` go in `test/tuner/framing.test.ts`. Shared test helpers go in `test/` too. Give each rule a case that it catches and a case that it lets through.
- `npm run coverage` runs the tests and measures coverage. Statements, branches, functions, and lines must each stay at 98% or more, or the run fails. To leave a file out, add it to the coverage `exclude` list in `vitest.config.js` with a comment that gives the reason. It runs `npm run coverage:lua` first, which writes the Lua fixtures that `test/contract.test.ts` reads.
- The CI `test` job installs Lua 5.1.5, LuaRocks, busted, and luacov, and runs `npm run coverage`. It puts the TypeScript and Lua coverage tables in the job summary and uploads the HTML report as the `coverage-report` artifact.
- CI runs lint, typecheck, and test as separate jobs in `.github/workflows/ci.yml`, plus an `actionlint` job that checks the workflow files. Lint and test need Node 26 or later. `.nvmrc` sets the Node version for CI.
- `npm run test:lua` runs busted on the core mod's Lua tests, with the settings in `.busted`. Lua tests go in `packages/core/mod/Test/`, which mirrors the mod folder and uses PascalCase, as `Scripts/` and `UI/` do. A test file ends in `.test.lua`, so the tests for `Scripts/SentientSystemsCore_Common.lua` go in `Test/Scripts/SentientSystemsCore_Common.test.lua`. `Test/Game.lua` loads a mod file into an environment that matches the game's Lua. Its `include` finds files through `ImportFiles` in the `.modinfo`, as the game does, so a file missing from the `.modinfo` fails in the tests too.
- The Lua tests also record the JSON that each top-level call returns, such as `SentientSystems_GetState`, as fixtures in `packages/core/bridge/test/lua-fixtures/`, which `.gitignore` lists. `Test/Game.lua` wraps the calls and writes one file per call, named by the test file and the call's order in it. `npm run test:lua` and `npm run coverage:lua` empty the folder first. `packages/core/bridge/test/contract.test.ts` parses each fixture with the schema the bridge reads it with, and fails with a message that names `npm run test:lua` when the folder is empty. A fake game that leaves out a field the real game always has, such as a city's position, fails the test too, so give the fake a default.
- `npm run coverage:lua` runs busted with luacov, using the settings in `.luacov`, and prints the coverage table. Lines must stay at 98% or more, or the run fails. A mod file that no test loads counts as 0%. The report is in `coverage/lua/`.
- Lua test helpers use PascalCase, as the mod's Lua files do, but skip the `SentientSystemsCore_` prefix. The prefix keeps the game's `include` from loading another mod's file, and test files never load in the game. A test loads a helper with `require`, such as `local Game = require("Game")`.
- The Lua tests need Lua 5.1.5, because the game's Lua matches it. See [lua/contexts.md](../findings/lua/contexts.md#lua-51-comparison). To install Lua 5.1.5, LuaRocks, busted, and luacov:
  1. Run `pip install hererocks`.
  2. Run `python -m hererocks <folder> -l 5.1 -r latest`. On Windows, hererocks builds Lua with the Visual Studio C++ tools.
  3. Add `<folder>\bin` to your `PATH`.
  4. Run `luarocks install busted` and `luarocks install luacov`.
