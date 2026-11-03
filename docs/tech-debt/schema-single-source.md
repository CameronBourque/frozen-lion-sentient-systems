# Schema single source

Each state section and choice has its shape written in up to five places. The zod schema in the bridge becomes the only one, and the other copies link to it. See the [tech debt index](README.md).

## Now

One field, such as `routes[].blocked` in the spy choice, is described in these places:

- The zod schema in `packages/core/bridge/src/choices/spies.ts`.
- The comment above that schema, which lists every field again in prose.
- The header comment of `packages/core/mod/Scripts/Choices/SentientSystemsCore_ChoicesSpies.lua`, with an `Example:` of the JSON.
- The comment above `SentientSystems_GetSpyChoices`, which lists the fields again.
- The key tables in [in-game-lua.md](../design/core/in-game-lua.md).

[in-game-lua.md](../design/core/in-game-lua.md) is 53,804 bytes, about 13,000 tokens, and most feature work reads or edits it. Its key tables, for the state, the choices, the placement, and the trees, are about two thirds of it.

The bridge has 18 schema files in `src/state/` besides `sizes.ts`, 15 in `src/choices/`, 2 in `src/trees/`, and 1 in `src/placement/`. 37 files in `packages/core/mod/Scripts/` have an `Example:` block.

The [findings](../findings/README.md) are large too, about 344 KB, but they hold the game's calls and how each was checked, not the JSON's fields. They stay as they are.

[code.md](../rules/code.md#comments) says to keep data shapes out of comments and to describe them in a document under `docs/`. That rule sends the shapes to [in-game-lua.md](../design/core/in-game-lua.md), away from the schemas.

## Proposal

The zod schemas hold the shape of the core mod's JSON. A field whose name doesn't say what it means gets a `.describe()` note on the schema, such as how it is rounded or which screen it matches. The key tables, the prose comments above the schemas, and the field lists and examples in the Lua comments go. [in-game-lua.md](../design/core/in-game-lua.md) keeps the mechanisms and links to the schema folders.

## Questions

1. Does the generated reference go in `docs/reference/`, which [phase 1 step 10](../roadmap/phase-1/10-tool-reference.md) plans, or beside the schemas? Answered: neither. No reference is generated for now. Each schema file is 13 to 85 lines, so an agent reads the one it needs instead of a large generated file. `z.toJSONSchema()` carries the `.describe()` notes, so step 9 can give them to the model if it adds output schemas to the tools. Step 9 decides that, because output schemas add tokens to every request.
2. Is the generated file committed and checked in CI, or built on demand? Answered: there is no generated file, so neither.

## Tasks

Each move task does the same four things for its files:

1. Move each note from the [in-game-lua.md](../design/core/in-game-lua.md) rows and from the comment above the schema into a `.describe()` on the field it is about, when the field's name doesn't already say it.
2. Delete those rows. When a table has no rows left, replace it with a link to the schema folder.
3. Cut the comment above each schema to its purpose and the Lua file that builds it.
4. Cut the Lua comments to the purpose, the screen file they follow, and any quirk, and delete the `Example:` blocks. Where an example shows something no test does, add the test.

The tasks:

1. **Rule.** In [code.md](../rules/code.md#comments), make the zod schemas in `packages/core/bridge/src/` the home of the core mod's JSON shapes, with `.describe()` for a field whose name doesn't say what it means. Add the row to the "Where each kind of fact lives" table in [docs.md](../rules/docs.md#no-repetition). Commit: `docs: make the zod schemas the home of the JSON shapes`.
2. **Map state.** The `blockers`, `cities`, `units`, `tiles`, and `rivals` sections: `blockers.ts`, `cities.ts`, `units.ts`, `tiles.ts`, `rivals.ts`, and `state.ts`, and their Lua files in `Scripts/State/`, with `SentientSystemsCore_State.lua`. Commit: `refactor(core): move the map state shapes into the schemas`.
3. **Player state.** The `player` section: `player.ts`, `income.ts`, `era.ts`, and `resources.ts`, and `SentientSystemsCore_StatePlayer*.lua`. Commit: `refactor(core): move the player state shapes into the schemas`.
4. **Rival state.** The `diplomacy`, `proposals`, `scoreboard`, and `victories` sections, and `SentientSystemsCore_StateVictories*.lua`. Commit: `refactor(core): move the rival state shapes into the schemas`.
5. **Other state.** The `envoys`, `governors`, `greatPeople`, and `religion` sections. This empties the state table. Commit: `refactor(core): move the other state shapes into the schemas`.
6. **City choices.** `production`, `purchases`, `techs`, `civics`, `government`, `policies`, and `governments`: `production.ts`, `purchases.ts`, `research.ts`, `government.ts`, and `choices.ts`, and their Lua files in `Scripts/Choices/`, with `SentientSystemsCore_Choices.lua`. Commit: `refactor(core): move the city choice shapes into the schemas`.
7. **Player choices.** `pantheon`, `religion`, `envoys`, `greatPeople`, `governors`, and `dedications`. Commit: `refactor(core): move the player choice shapes into the schemas`.
8. **Event choices.** `capturedCities`, `spies`, `artifacts`, `emergencies`, and `worldCongress`. This empties the choices table. Commit: `refactor(core): move the event choice shapes into the schemas`.
9. **Placement and trees.** `src/placement/placement.ts`, `src/trees/research.ts`, and `src/trees/governors.ts`, and their Lua files in `Scripts/Placement/` and `Scripts/Trees/`. This empties the last tables. Commit: `refactor(core): move the placement and tree shapes into the schemas`.
10. **Other examples.** Delete the `Example:` blocks in `SentientSystemsCore_Common.lua` and `SentientSystemsCore_Json.lua`, as step 4 of the list above says. Commit: `refactor(core): drop the examples from the shared Lua comments`.

## Done when

- Each field is described once, in its zod schema.
- [in-game-lua.md](../design/core/in-game-lua.md) has no key tables.
- No Lua or TypeScript comment lists a schema's fields or has an `Example:` block.
