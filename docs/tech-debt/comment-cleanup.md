# Comment cleanup

Older comments break the comment rules in [code.md](../rules/code.md#comments), and no lint rule stops new ones. Agents copy what they read, so the old style keeps coming back. See the [tech debt index](README.md).

## Now

Comment lines over 80 columns, counting a tab as 4, on 2026-11-02:

| Folder | Lines |
| --- | --- |
| `packages/core/bridge/src/` schema folders: `state/`, `choices/`, `trees/`, and `placement/` | 282 |
| The rest of `packages/core/bridge/src/` | 135 |
| `packages/core/bridge/test/` and `scripts/` | 140 |
| `scripts/`, `eslint.config.js`, `vitest.config.js`, `.busted`, and `.luacov` | 55 |
| `packages/core/mod/Scripts/State/` | 334 |
| `packages/core/mod/Scripts/Choices/` | 309 |
| The rest of `packages/core/mod/Scripts/`, and `UI/` | 144 |
| `packages/core/mod/Test/FakeGame/`, `FakeGame.lua`, and `Game.lua` | 354 |
| The rest of `packages/core/mod/Test/` | 65 |

[schema-single-source.md](schema-single-source.md) and [fake-game-registry.md](fake-game-registry.md) delete many of these comments first, so this debt rewraps only the ones that remain. Count again before each task.

`npm run lint` runs ESLint only. The CI `lint` job installs Node and no Lua.

## Proposal

Rewrap every comment to 80 columns, one folder group per commit, with no change to the wording. Then turn on a limit for comments in ESLint, and add a short Node script to `npm run lint` that checks the Lua comments.

## Questions

1. Does this run before or with [schema-single-source.md](schema-single-source.md)? Answered: after it, because that debt deletes many of the comments this one would rewrap.
2. Is `luacheck` worth a new dev tool, or is a short script enough? Answered: a short script. The CI `lint` job has no Lua, so `luacheck` would need Lua installed there. `luacheck` would also need its other checks turned off, because the game's globals, such as `Players`, would fail them.

## Tasks

Each rewrap task changes only line breaks in full-line comments. Comment length isn't checked until task 5 for TypeScript and JavaScript, and task 11 for Lua, so each commit passes lint by itself. The PR title check has no `style` type, so the rewraps use `chore`.

1. **Bridge schemas.** Rewrap the comments in `packages/core/bridge/src/state/`, `choices/`, `trees/`, and `placement/`. Commit: `chore(core): wrap the schema comments at 80 columns`.
2. **Bridge source.** Rewrap the rest of `packages/core/bridge/src/`. Commit: `chore(core): wrap the bridge comments at 80 columns`.
3. **Bridge tests and scripts.** Rewrap `packages/core/bridge/test/` and `packages/core/bridge/scripts/`. Commit: `chore(core): wrap the bridge test and script comments at 80 columns`.
4. **Repo scripts and configs.** Rewrap `scripts/`, `eslint.config.js`, `vitest.config.js`, `.busted`, and `.luacov`. Commit: `chore: wrap the repo script and config comments at 80 columns`.
5. **ESLint rule.** Add `@stylistic/max-len` to the shared rules in `eslint.config.js`, with `comments: 80`, `tabWidth: 4`, and a `code` limit that no line reaches, so only comments are checked. Commit: `chore: limit comment lines to 80 columns in ESLint`.
6. **State Lua.** Rewrap `packages/core/mod/Scripts/State/`. Commit: `chore(core): wrap the state Lua comments at 80 columns`.
7. **Choices Lua.** Rewrap `packages/core/mod/Scripts/Choices/`. Commit: `chore(core): wrap the choice Lua comments at 80 columns`.
8. **Other mod Lua.** Rewrap the rest of `packages/core/mod/Scripts/`, and `UI/`. Commit: `chore(core): wrap the other mod Lua comments at 80 columns`.
9. **Fake game.** Rewrap `packages/core/mod/Test/FakeGame/`, `FakeGame.lua`, and `Game.lua`. Commit: `chore(core): wrap the fake game comments at 80 columns`.
10. **Lua tests.** Rewrap the rest of `packages/core/mod/Test/`. Commit: `chore(core): wrap the Lua test comments at 80 columns`.
11. **Lua check.** Add `scripts/lua-comments/`, which fails on a full-line Lua comment over 80 columns, counting a tab as 4, with its tests. Run it from `npm run lint`, and describe it under **Lint and test** in [code.md](../rules/code.md#lint-and-test). Commit: `chore: limit Lua comment lines to 80 columns`.

## Done when

- `npm run lint` fails on a comment line over 80 columns, in Lua and TypeScript.
