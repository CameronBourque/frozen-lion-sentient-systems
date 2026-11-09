# Nested objects

A pair of values that always go together, such as a tile's `x` and `y`, is written out inline in schemas and function signatures, and objects nest inside objects with no name, so the same idea has many spellings and the bridge has no type to pass around.

## Now

The counts come from a scan of `packages/core/bridge/src/`.

**Positions.** A tile position, `x` and `y`, is declared inline in 10 schemas: `choices/artifacts.ts`, `choices/captured-cities.ts`, `choices/purchases.ts`, `placement/placement.ts`, `state/cities.ts` (twice), `state/rivals.ts` (twice), `state/tiles.ts`, and `state/units.ts`.

It is also a loose pair in function signatures: `moveUnit` in `actions/units.ts`, and `cityAttack` and `purchaseTile` in `actions/cities.ts`. `setProduction` takes it as an inline `{ x: number; y: number }`, and the `UnitAction` type in `actions/units.ts` repeats the pair in its union.

**References.** A city named by `owner` and `id` is `CITY_ID` in `src/schemas.ts`, and `CITY_REF` adds its name. Every schema uses them. A unit is named by its ID alone, because the player only acts on their own units.

**Objects with objects inside.** 49 schema fields are an inline `z.object` in another object, in 12 files. The most are in `state/cities.ts` (8), `state/diplomacy.ts` (7), and `state/player.ts` (4).

Examples are `moves: z.object({ left, max })` in `state/units.ts` and `turnsUntilNext: z.object({ min, max })` in `state/era.ts`.

An inline object has no name, so a reader can't tell whether two of them are the same idea, and a function that takes one has to spell its shape out again.

## Proposal

Give each repeated shape one named schema and type, and use it everywhere. Start with `Position`, a schema and type of `x` and `y`.

The signatures take the object: `moveUnit(client, playerID, unitID, position)`, `purchaseTile(client, playerID, cityID, position)`, and `tile?: Position` in `setProduction`. The Lua calls keep their separate `x` and `y` arguments, so the bridge builds the call from the object.

Then move each inline nested object that has a meaning of its own into a named schema in the same file, such as `Moves` or `Range`. Leave a small object that appears once and has no use outside its parent.

`Position` goes in `src/schemas.ts`, with the city references. Do `Position` first, one commit for the schema and one for each file that moves to it, and the nested objects after.

## Questions

1. How much nesting earns a name? A rule, such as "a name when it appears twice, or when a function takes it", settles the 49 fields without extracting every one.
2. Does a shared `Position` schema keep each field's description? Several schemas describe `x` and `y` differently, and the model reads those descriptions.
3. Does a Lua position table follow the same change, or stay as separate values? The Lua side builds `{ x, y }` tables in the placement and choices files, which this scan did not count.

## Done when

`Position` has one definition, and the action functions take it and the city references in place of loose values. No inline nested object in `packages/core/bridge/src/` appears twice or is passed to a function. The bridge tests and coverage pass.
