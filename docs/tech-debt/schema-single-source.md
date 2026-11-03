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

Each move task changes, for each of its sections, the schema file in `packages/core/bridge/src/`, the Lua file that builds it in `packages/core/mod/Scripts/`, and [in-game-lua.md](../design/core/in-game-lua.md). That is 3 to 7 files per commit. It does the same four things for its files:

1. Move each note from the [in-game-lua.md](../design/core/in-game-lua.md) rows and from the comment above the schema into a `.describe()` on the field it is about, when the field's name doesn't already say it.
2. Delete those rows. When a table has no rows left, replace it with a link to the schema folder.
3. Cut the comment above each schema to its purpose and the Lua file that builds it.
4. Cut the Lua comments to the purpose, the screen file they follow, and any quirk, and delete the `Example:` blocks. Where an example shows something no test does, add the test.

The tasks:

1. **Rule.** In [code.md](../rules/code.md#comments), make the zod schemas in `packages/core/bridge/src/` the home of the core mod's JSON shapes, with `.describe()` for a field whose name doesn't say what it means. Add the row to the "Where each kind of fact lives" table in [docs.md](../rules/docs.md#no-repetition). Commit: `docs: make the zod schemas the home of the JSON shapes`.
2. **Blockers and units.** The state's `blockers` and `units`. Commit: `refactor(core): move the blocker and unit shapes into the schemas`.
3. **Cities.** The state's `cities`. Commit: `refactor(core): move the city shapes into the schemas`.
4. **Tiles and rivals.** The state's `tiles` and `rivals`, with `state.ts` and `SentientSystemsCore_State.lua`. Commit: `refactor(core): move the tile and rival shapes into the schemas`.
5. **Player and resources.** `player`, with `player.ts`, `resources.ts`, `SentientSystemsCore_StatePlayer.lua`, and `SentientSystemsCore_StatePlayerResources.lua`. Commit: `refactor(core): move the player and resource shapes into the schemas`.
6. **Income.** `player.income`. Commit: `refactor(core): move the income shapes into the schemas`.
7. **Era.** `player.era`. Commit: `refactor(core): move the era shapes into the schemas`.
8. **Diplomacy and proposals.** The state's `diplomacy` and `proposals`. Commit: `refactor(core): move the diplomacy and proposal shapes into the schemas`.
9. **Scoreboard.** The state's `scoreboard`. Commit: `refactor(core): move the scoreboard shapes into the schemas`.
10. **Victories.** The state's `victories`, with the five `SentientSystemsCore_StateVictories*.lua` files. Commit: `refactor(core): move the victory shapes into the schemas`.
11. **State envoys and religion.** The state's `envoys` and `religion`. Commit: `refactor(core): move the state envoy and religion shapes into the schemas`.
12. **State governors and great people.** The state's `governors` and `greatPeople`. This empties the state table. Commit: `refactor(core): move the state governor and great people shapes into the schemas`.
13. **Production and purchases.** The choices' `production` and `purchases`, with `choices.ts` and `SentientSystemsCore_Choices.lua`. Commit: `refactor(core): move the production and purchase shapes into the schemas`.
14. **Research and government.** The choices' `techs`, `civics`, `government`, `policies`, and `governments`. Commit: `refactor(core): move the research and government shapes into the schemas`.
15. **Religion, envoy, and great people choices.** The choices' `pantheon`, `religion`, `envoys`, and `greatPeople`. Commit: `refactor(core): move the religion, envoy, and great people choice shapes into the schemas`.
16. **Governor and dedication choices.** The choices' `governors` and `dedications`. Commit: `refactor(core): move the governor and dedication choice shapes into the schemas`.
17. **Captured city, spy, and artifact choices.** The choices' `capturedCities`, `spies`, and `artifacts`. Commit: `refactor(core): move the captured city, spy, and artifact shapes into the schemas`.
18. **Emergency and World Congress choices.** The choices' `emergencies` and `worldCongress`. This empties the choices table. Commit: `refactor(core): move the emergency and World Congress shapes into the schemas`.
19. **Placement.** `src/placement/placement.ts` and `Scripts/Placement/`. Commit: `refactor(core): move the placement shapes into the schemas`.
20. **Trees.** `src/trees/research.ts`, `src/trees/governors.ts`, and `Scripts/Trees/`. This empties the last tables. Commit: `refactor(core): move the tree shapes into the schemas`.
21. **Other examples.** Delete the `Example:` blocks in `SentientSystemsCore_Common.lua` and `SentientSystemsCore_Json.lua`, as step 4 of the list above says. Commit: `refactor(core): drop the examples from the shared Lua comments`.

## Done when

- Each field is described once, in its zod schema.
- [in-game-lua.md](../design/core/in-game-lua.md) has no key tables.
- No Lua or TypeScript comment lists a schema's fields or has an `Example:` block.
