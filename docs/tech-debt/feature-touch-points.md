# Feature touch points

A new state section or choice touches 12 places across Lua, TypeScript, and the docs. Each time, an agent must find all of them before it writes code. See the [tech debt index](README.md).

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
11. The key table in [in-game-lua.md](../design/core/in-game-lua.md).
12. The finding for the screen, and its row in the [findings index](../findings/README.md).

A choice touches the same places under `Choices/` and `src/choices/`.

The earlier debts cut this list. The contract test checks each section against the JSON from its Lua test, so a new section needs no TypeScript test of its own, and [schema-single-source.md](schema-single-source.md) removes place 11. The fake game registry is already cut, so place 7 is one line. That leaves 11 places, and 5 of them are one-line edits.

A missed place fails a test, except for two. A missing `<Files>` entry passes, which task 1 here fixes. A missing finding is a docs step, which review catches.

Nothing checks that the `<ImportFiles>` and `<Files>` lists in the `.modinfo` match. `Test/Game.lua` reads `<ImportFiles>` only, so a file missing from `<Files>` passes the tests.

## Proposal

List the parts of a state section and a choice in the [core README](../../packages/core/README.md), so an agent reads one list instead of searching. Test that the two `.modinfo` lists match. No script creates the files.

## Questions

1. Is a script worth it, or is a short list of the places in [code.md](../rules/code.md) enough? Answered: a list, in the [core README](../../packages/core/README.md), because the parts span the mod and the bridge. Phase 1's remaining steps add actions, lookups, and tools, not sections, and later phases add a few. A script would be about as long as the code it writes, would need tests of its own, and would need a change each time the layout changes.
2. Does the action API in [phase 1 step 7](../roadmap/phase-1/07-action-api.md) add its own places, which the script must also cover? Answered: yes, an action has its own parts, such as its Lua function, `src/actions.ts`, and their tests. Step 7 adds them to the same list.

## Tasks

1. **`.modinfo` check.** In `Test/Game.test.lua`, test that each file in `<ImportFiles>` is also in `<Files>`, and that each file under `Scripts/` in `<Files>` is also in `<ImportFiles>`. Commit: `test(core): check that the .modinfo file lists match`.
2. **Parts list.** Add a section to the [core README](../../packages/core/README.md) that lists the parts of a state section and of a choice, with the path of each. In the `## Record` of [step 7](../roadmap/phase-1/07-action-api.md), add the parts of an action to that list. Commit: `docs(core): list the parts of a state section and a choice`.

## Done when

- A new state section or choice needs no search to find where it goes.
- A `.modinfo` with a file in only one of its lists fails a test.
