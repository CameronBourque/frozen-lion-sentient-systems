# Schema contract fixtures

The TypeScript schema tests check hand-copied fixtures. Fixtures written by the Lua tests replace them, so one test checks that what the core mod builds matches what the bridge expects. See the [tech debt index](README.md).

## Now

`packages/core/bridge/test/state/`, `test/choices/`, and `test/trees/` hold 2,081 lines. Most tests check that the schema accepts one hand-written object and rejects it with a field missing, such as the tests in `test/choices/spies.test.ts`. Those tests check zod more than they check the bridge.

The hand-written fixture and the JSON that the Lua builds can drift apart. Nothing checks that the two match.

## Proposal

1. In the busted tests, write the JSON that `SentientSystems_GetState`, `SentientSystems_GetChoices`, and the tree calls return from the fake game to fixture files.
2. Add one Vitest file that parses each fixture with its schema.
3. Delete the schema tests that only accept or reject a hand-written object. Keep tests for logic the schema holds, such as a refinement or a default.

## Questions

1. Are the fixtures committed, or written to `tmp/` on each run? Committed fixtures let `npm test` run without Lua, but they need a check that they are current.
2. Do the fixtures cover each optional section, such as the era without Rise and Fall? The Lua tests decide this, so a gap there becomes a gap here.

## Done when

- `npm run coverage` parses every fixture that the Lua tests write.
- A schema change that the Lua doesn't match fails a test.
- The schema test folders have no hand-copied fixtures.
