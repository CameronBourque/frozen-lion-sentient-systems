# Test rules

How the tests run, where they go, and the coverage they need, in every package. Lint is in [code.md](code.md#lint).

## Tests and coverage

- `npm test` runs Vitest. Put code in a `src/` folder and tests in a `test/` folder beside it, in each package and script folder.

  `test/` mirrors `src/`, so the tests for `src/tuner/framing.ts` go in `test/tuner/framing.test.ts`. Shared test helpers go in `test/` too. Give each rule a case that it catches and a case that it lets through.

  `startGame` in `test/tuner/fake-game.ts` starts the fake game and connects a client for a test, and closes both when the test ends.
- `npm run coverage` runs the tests and measures coverage. Statements, branches, functions, and lines must each stay at 98% or more, or the run fails.

  To leave a file out, add it to the coverage `exclude` list in `vitest.config.js` with a comment that gives the reason. It runs `npm run coverage:lua` first, which writes the Lua fixtures that `test/contract.test.ts` reads.
- The CI `test` job installs Lua 5.1.5, LuaRocks, busted, and luacov, and runs `npm run coverage`. It puts the TypeScript and Lua coverage tables in the job summary and uploads the HTML report as the `coverage-report` artifact.
- CI runs lint, typecheck, and test as separate jobs in `.github/workflows/ci.yml`, plus an `actionlint` job that checks the workflow files. Lint and test need Node 26 or later. `.nvmrc` sets the Node version for CI.
- `npm run test:lua` runs busted on the core mod's Lua tests, with the settings in `.busted`. Lua tests go in `packages/core/mod/Test/`, which mirrors the mod folder and uses PascalCase, as `Scripts/` and `UI/` do.

  A test file ends in `.test.lua`, so the tests for `Scripts/SentientSystemsCore_Common.lua` go in `Test/Scripts/SentientSystemsCore_Common.test.lua`.

  `Test/Game.lua` loads a mod file into an environment that matches the game's Lua. Its `include` finds files through `ImportFiles` in the `.modinfo`, as the game does, so a file missing from the `.modinfo` fails in the tests too.

  `Test/Helpers.lua` holds the helpers that many tests share, such as `With`, which copies a table with changes. Add a helper there once a second test file needs it.
- The Lua tests also record the JSON that each top-level call returns, such as `SentientSystems_GetState`, as fixtures in `packages/core/bridge/test/lua-fixtures/`, which `.gitignore` lists.

  `Test/Game.lua` wraps the calls and writes one file per call, named by the test file and the call's order in it. `npm run test:lua` and `npm run coverage:lua` empty the folder first.

  `packages/core/bridge/test/contract.test.ts` parses each fixture with the schema the bridge reads it with, and fails with a message that names `npm run test:lua` when the folder is empty.

  A fake game that leaves out a field the real game always has, such as a city's position, fails the test too, so give the fake a default.

  A fake doesn't copy a constant from the code it stands in for. The test gives the value in the fake's data, so a typo in the code fails the test.
- `npm run coverage:lua` runs busted with luacov, using the settings in `.luacov`, and prints the coverage table. Lines must stay at 98% or more, or the run fails. A mod file that no test loads counts as 0%. The report is in `coverage/lua/`.
- Lua test helpers use PascalCase, as the mod's Lua files do, but skip the `SentientSystemsCore_` prefix. The prefix keeps the game's `include` from loading another mod's file, and test files never load in the game. A test loads a helper with `require`, such as `local Game = require("Game")`.
- The Lua tests need Lua 5.1.5, because the game's Lua matches it. See [lua/dialect.md](../findings/lua/dialect.md#lua-51-comparison). To install Lua 5.1.5, LuaRocks, busted, and luacov:
  1. Run `pip install hererocks`.
  2. Run `python -m hererocks <folder> -l 5.1 -r latest`. On Windows, hererocks builds Lua with the Visual Studio C++ tools.
  3. Add `<folder>\bin` to your `PATH`.
  4. Run `luarocks install busted` and `luarocks install luacov`.
