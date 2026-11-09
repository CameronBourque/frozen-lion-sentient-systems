# Code rules

Rules for code in every package. Each architecture rule links to the design decision that explains it. The tests and coverage are in [testing.md](testing.md).

## Architecture

- [Only core talks to the game. Feature mods use the core API and never call FireTuner or game Lua directly](../design/architecture.md#core-boundary).
- [Move code into core only when a second mod needs it](../design/architecture.md#core-boundary).
- [Actions go through the game's own request functions, so the game checks legality](../design/core/mod/actions.md).
- [Agent state comes from the player's visibility data, never from the screen](../design/core/mod/state.md#decisions).
- [Every failed action returns a reason](../design/core/mod/actions.md#decisions).
- [Every action tool has a required `reason` field](../design/agents/narration-and-messaging.md#narrator-panel).
- [The API key never goes into a game setup parameter](../design/core/settings.md).
- [A file format change bumps that file's schema version and ships a migration](../design/versioning.md#bump-rules).
- [A helper that several core mod scripts share lives in the smallest file that every caller loads](../design/core/mod/README.md#decisions).
- [A schema that several bridge files share lives in `src/schemas.ts`](../design/core/bridge.md#decisions).

## Conventions

These conventions come from `scripts/check-docs/`, the first code in the repo. Expect them to change as the bridge and the mods add code.

- **Use the standard library before a dependency.** Add a package only when the standard library can't do the job. Dev tools, such as the linter and the test runner, live in the root `package.json`.
- **Share what several files repeat.** When two files do the same thing, move it into one helper that both call, and pass in what differs as parameters. A one-line helper is fine when several files call it and its parameters change what it does.

  Inline a helper that only renames another call, and pass a function itself in place of a closure that only calls it.
- **Give each function a name of its own.** In the core mod's Lua, no two functions share a name, even local ones in different files. Name a function for what it returns, such as `GetHeldPromotions`, so a search finds the one it means.
- **Keep nesting shallow.** When loops nest three or more deep, move the inner ones into a named helper.
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
- **Keep data shapes out of comments.** This includes the fields that a test fake reads from its data. The zod schemas in `packages/core/bridge/src/` are the home of the core mod's JSON shapes.

  Give a field a `.describe()` note when its name doesn't say what it means, such as how it is rounded or which screen it matches. Link to the schema from the code.
- **Keep examples out of comments.** Write them as tests.
- **Name the game's function, not its line numbers.** When code copies a game function, name the function and its file. Line numbers go stale when the game updates, and the name still finds the code.
- **Don't repeat a document.** Link to it instead.
- **Keep comment lines to 80 characters or fewer.**

## TypeScript

The bridge's TypeScript setup. Why each choice was made is in [design/core/toolchain.md](../design/core/toolchain.md#decisions).

- **Node 26.** `.nvmrc` and the `engines` fields set it, and the bridge executable ships with it. Node 26 is an LTS release, supported until 2029-04-30. Move the repo to the next LTS release before then, so the executable never ships a runtime without security fixes.
- **`tsx` runs TypeScript in development.** TypeScript features that need more than removing types, such as enums, are allowed.
- **Pass a script's arguments after `--`.** Write `npm run state -- 1` in docs and comments. In PowerShell, write the `--` as `'--'`: `npm run state '--' 1`.

  On Windows, `npm` in PowerShell is the script `npm.ps1`, and PowerShell drops a bare `--` before it calls a script. npm then reads the arguments as its own settings, and the script never gets them. cmd keeps the quotes, so it needs the bare `--`.
- **`tsc` only type-checks.** `npm run typecheck` runs it with `noEmit`, as its own CI job. esbuild bundles the release, so nothing uses compiled output.
- **TypeScript 6 loads no `@types` packages by default.** The bridge `tsconfig.json` lists `"types": ["node"]`. Add a package there when its types are needed.
- **ES modules, with no namespaces.** Group code by file, and import what each file needs. `declare namespace` in a `.d.ts` file is still allowed, to describe a library's types.
- **Lint rules.** `.ts` files use typescript-eslint's `recommended` rules, plus these rules that need type information:
  - promises: `no-floating-promises`, `no-misused-promises`, `await-thenable`, and `require-await`,
  - values typed `any`: `no-unsafe-argument`, `no-unsafe-assignment`, `no-unsafe-call`, `no-unsafe-enum-comparison`, `no-unsafe-member-access`, `no-unsafe-return`, and `no-unsafe-unary-minus`,
  - errors: `only-throw-error` and `prefer-promise-reject-errors`.

## Lint

- `npm run lint` runs ESLint with the rules in `eslint.config.js`. It checks tabs, trailing spaces, and blank lines: one after a run of definitions, one before and after each block, and one before `return`.

  It also runs `scripts/lua-comments/`, which fails on a full-line Lua comment over 80 columns, counting a tab as 4 and a character as 1. ESLint can't read Lua, and the CI `lint` job has no Lua tool.
- Lint also checks these [comment rules](#comments), in Lua and in TypeScript, from the shared code in `scripts/comment-rules/`. A broken rule fails the build.
  - A file header over three lines. The header is the first comment before any code, up to the first blank line.
  - A comment block of two or more lines with no code on the line after it. A block sits directly above the code it describes, so a blank line after it fails, and so does a header that goes on in a second block. A one-line comment can stand alone.
  - A line number, such as "line 12" or "lines 3 to 5".
  - "such as", "for example", or "for instance" followed by a quoted or code example.
  - A data shape: `{` followed by a quote, a quoted key before a colon, or a `{` around two or more bare names, such as the fields of a row.
  - These are heuristics, so a comment can opt out of the line number, example, JSON shape, and stray block rules by holding `comment-lint-ignore:` and a short reason. A marker with no reason skips nothing.

    It covers only its own comment line, or its own block for the stray block rule. The header and line width checks have no opt-out.
  - A path to a doc that doesn't exist, or a path with a `*` whose file does exist, as [docs.md](docs.md#structure) describes. It has no opt-out, because a doc that isn't written yet takes a `*`. `scripts/yml-comments/` runs it on yml comments, because ESLint can't read yml.
  - Lint can't see a comment that restates the next line of code, or a data shape written as prose, such as the fields that a test fake reads from its data. Those stay with review.
