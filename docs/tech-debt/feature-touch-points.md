# Feature touch points

A new state section or choice touches 13 places across Lua, TypeScript, and the docs. Each time, an agent must find all of them before it writes code. See the [tech debt index](README.md).

## Now

A new state section touches these places:

1. The Lua file in `packages/core/mod/Scripts/State/`.
2. The `SentientSystems_Include` line in `SentientSystemsCore_State.lua`.
3. The key in that file's table.
4. The `<ImportFiles>` list in `SentientSystemsCore.modinfo`.
5. The `<Files>` list in the same file.
6. The fake game feature in `packages/core/mod/Test/FakeGame/`.
7. Its `FakeGame.Register` line in `Test/FakeGame.lua`.
8. The Lua test.
9. The zod schema in `packages/core/bridge/src/state/`.
10. Its import and key in `src/state/state.ts`.
11. The TypeScript test.
12. The key table in [in-game-lua.md](../design/core/in-game-lua.md).
13. The finding for the screen, and its row in the [findings index](../findings/README.md).

A choice touches the same places under `Choices/` and `src/choices/`.

## Proposal

1. [schema-single-source.md](schema-single-source.md) removes place 12. [schema-contract-fixtures.md](schema-contract-fixtures.md) removes place 11. [fake-game-registry.md](fake-game-registry.md) shortens place 7.
2. Add a script, such as `npm run new-section <name>`, that creates the files and adds the lines in places 1 to 10.
3. Add a test that the `<ImportFiles>` and `<Files>` lists in the `.modinfo` match.

## Questions

1. Is a script worth it, or is a short list of the places in [code.md](../rules/code.md) enough?
2. Does the action API in [phase 1 step 7](../roadmap/phase-1/07-action-api.md) add its own places, which the script must also cover?

## Done when

- A new state section or choice needs no search to find where it goes.
- A `.modinfo` with a file in only one of its lists fails a test.
