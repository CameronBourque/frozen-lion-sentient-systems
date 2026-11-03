# Schema contract fixtures

The TypeScript schema tests check hand-copied fixtures. Fixtures written by the Lua tests replace them, so one test checks that what the core mod builds matches what the bridge expects. See the [tech debt index](README.md).

## Now

`packages/core/bridge/test/state/` and `test/choices/` hold 31 schema test files, 1,494 lines, besides `state.test.ts`, `sizes.test.ts`, and `choices.test.ts`. Most of their tests check that a schema accepts one hand-written object and rejects it with a field missing, such as the tests in `test/choices/spies.test.ts`. Those tests check zod more than they check the bridge.

The reader tests in `state.test.ts`, `choices.test.ts`, `test/trees/`, and `test/placement/` also hold schema cases, such as "fails for a status the screen doesn't use" in `test/trees/research.test.ts`.

The hand-written fixture and the JSON that the Lua builds can drift apart. Nothing checks that the two match.

The schemas aren't strict, so parsing drops a field or a whole section that the schema doesn't name, with no error. A section built and tested in the Lua, but missing from its schema or from `state.ts`, never reaches the agent, and no test fails.

Every Lua test of the state, the choices, the trees, and the placement reads its JSON through the top-level call, such as `SentientSystems_GetState(0)`, often in a helper at the top of the test file.

## Proposal

`Test/Game.lua` records the JSON that each top-level call returns during the Lua tests, in `packages/core/bridge/test/lua-fixtures/`, which `.gitignore` lists. The bridge tests are the only reader. One Vitest file parses each recorded JSON with its schema, and checks that parsing dropped nothing. The hand-written schema tests go, and the reader tests keep only reader behavior.

## Questions

1. Are the fixtures committed, or written on each run? Answered: written on each run to `packages/core/bridge/test/lua-fixtures/`, beside the tests that read them, and listed in `.gitignore`. Each run rebuilds them from the Lua in that checkout, so they always match it, and CI's `test` job writes them before Vitest runs. Committed fixtures would be hundreds of files that change with each Lua change and that agents may read. CI runs the Lua tests anyway.
2. Do the fixtures cover each optional section, such as the era without Rise and Fall? Answered: yes, as far as the Lua tests do. Every Lua test of these calls goes through the top-level call, so the fixtures hold every world the Lua tests build. The Lua line coverage stays at 98% or more, so the code for each optional section runs in at least one of those worlds.

## Tasks

1. **Record.** In `Test/Game.lua`, wrap `SentientSystems_GetState`, `SentientSystems_GetChoices`, `SentientSystems_GetTechTree`, `SentientSystems_GetCivicTree`, `SentientSystems_GetGovernorTree`, and `SentientSystems_GetPlacement` after a file defines them. Write each JSON they return to `packages/core/bridge/test/lua-fixtures/<call>/`, named by the test file and the call's order in it. Add the folder to `.gitignore`. Make `npm run test:lua` and `npm run coverage:lua` empty the folder first. Commit: `test(core): record the Lua JSON as fixtures`.
2. **Contract test.** Export the schemas that the readers use. Add `test/contract.test.ts`, which parses each fixture with its call's schema, and fails with a message that names `npm run test:lua` when the folder is empty. Make `npm run coverage` run the Lua tests first. Describe the fixtures under **Lint and test** in [code.md](../rules/code.md#lint-and-test). If the test finds a mismatch, fix it first in its own `fix(core):` commit. Commit: `test(core): check the Lua fixtures against the bridge schemas`.
3. **Drop check.** In `test/contract.test.ts`, check that each parsed fixture equals the raw JSON, so a field or a section that the schema doesn't name fails the test. The schemas have no defaults or transforms, so a parse that drops nothing returns the same value. Add each field the check finds missing to its schema first, in its own `fix(core):` commit. Commit: `test(core): fail when a schema drops a field from the Lua JSON`.
4. **Schema tests.** Delete the 31 schema test files in `test/state/` and `test/choices/`. Keep `state.test.ts`, `sizes.test.ts`, and `choices.test.ts`. Commit: `test(core): drop the hand-written schema tests`.
5. **Reader tests.** In `state.test.ts`, `choices.test.ts`, `test/trees/research.test.ts`, `test/trees/governors.test.ts`, and `test/placement/placement.test.ts`, keep the tests of the call, the errors, and the type name check. Delete the tests of schema shapes, and cut each fixture to the smallest one the remaining tests need. Commit: `test(core): cut the reader tests to reader behavior`.

## Done when

- `npm run coverage` parses every fixture that the Lua tests write.
- A schema change that the Lua doesn't match fails a test.
- A field or a section that the Lua sends and no schema names fails a test.
- The bridge tests have no hand-copied fixture larger than a reader test needs.
