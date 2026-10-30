# Schema single source

Each state section and choice has its shape written in up to five places. The zod schema in the bridge becomes the only one, and the other copies link to it. See the [tech debt index](README.md).

## Now

One field, such as `routes[].blocked` in the spy choice, is described in these places:

- The zod schema in `packages/core/bridge/src/choices/spies.ts`.
- The comment above that schema, which lists every field again in prose.
- The header comment of `packages/core/mod/Scripts/Choices/SentientSystemsCore_ChoicesSpies.lua`, with an `Example:` of the JSON.
- The comment above `SentientSystems_GetSpyChoices`, which lists the fields again.
- The key tables in [in-game-lua.md](../design/core/in-game-lua.md), and in some cases the finding for that screen.

[in-game-lua.md](../design/core/in-game-lua.md) is 53,804 bytes, about 13,000 tokens, and most feature work reads or edits it. The [findings](../findings/README.md) total about 344 KB, and [game-choices.md](../findings/game-choices.md) alone is 29 KB.

The bridge has 19 schema files in `src/state/`, 15 in `src/choices/`, and 2 in `src/trees/`.

## Proposal

1. Put each field's note on the schema with zod's `.describe()`, in place of the prose comment above it.
2. Generate the reference for the state, the choices, and the trees with zod 4's `z.toJSONSchema()`. Phase 1 step 10 needs the same output for the tool reference, and the MCP server needs it for output schemas.
3. Cut the key tables in [in-game-lua.md](../design/core/in-game-lua.md) down to the mechanisms, such as tagged lines, the stash, errors, and JSON, and link to the generated reference.
4. Cut the field lists from the Lua comments. [comment-cleanup.md](comment-cleanup.md) removes the `Example:` blocks.
5. Trim the findings to the game calls, their quirks, and how they were checked.

## Questions

1. Does the generated reference go in `docs/reference/`, which [phase 1 step 10](../roadmap/phase-1/10-tool-reference.md) plans, or beside the schemas?
2. Is the generated file committed and checked in CI, or built on demand?

## Done when

- Each field is described once, in its zod schema.
- [in-game-lua.md](../design/core/in-game-lua.md) has no key tables, and it is under 150 lines.
- No Lua or TypeScript comment lists a schema's fields.
