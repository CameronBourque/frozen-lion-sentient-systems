# Nested objects

A pair of values that always go together, such as a tile's `x` and `y`, is written out inline in schemas and function signatures, and objects nest inside objects with no name, so the same idea has many spellings and the bridge has no type to pass around.

## Now

The counts come from a scan of `packages/core/bridge/src/` and `packages/core/mod/Scripts/`.

**Positions.** A tile position, `x` and `y`, is declared inline in 10 schemas: `choices/artifacts.ts`, `choices/captured-cities.ts`, `choices/purchases.ts`, `placement/placement.ts`, `state/cities.ts` (twice), `state/rivals.ts` (twice), `state/tiles.ts`, and `state/units.ts`.

None of these `x` and `y` fields has its own description.

It is also a loose pair in function signatures: `moveUnit` in `actions/units.ts`, and `cityAttack` and `purchaseTile` in `actions/cities.ts`. `setProduction` takes it as an inline `{ x: number; y: number }`.

The `UnitOrder` type in `actions/units.ts` repeats the pair in its union. Only the bridge tests call these functions.

**References.** A city named by `owner` and `id` is `CITY_ID` in `src/schemas.ts`, and `CITY_REF` adds its name. Every schema uses them. A unit is named by its ID alone, because the player only acts on their own units.

**Objects with objects inside.** 49 schema fields are an inline `z.object` in another object, in 12 files. The most are in `state/cities.ts` (8), `state/diplomacy.ts` (7), and `state/player.ts` (4).

Examples are `moves: z.object({ left, max })` in `state/units.ts` and `turnsUntilNext: z.object({ min, max })` in `state/era.ts`.

Among the objects written on one line, `{ balance, perTurn }` repeats, for `faith` and `favor` in `state/player.ts`. The inline `{ type, amount }` in `state/envoys.ts` has the shape of `YIELD` in `state/great-works.ts`, but it holds a resource.

An inline object has no name, so a reader can't tell whether two of them are the same idea, and a function that takes one has to spell its shape out again.

**Lua.** The Lua functions take a position as separate `x` and `y` arguments, as the game's own calls do, such as `Map.GetPlot(x, y)`.

Five places build the table `{ x = plot:GetX(), y = plot:GetY() }` by hand: `ActionsUnitAttacks.lua` (twice), `ActionsUnitTileOrders.lua`, `ChoicesPurchases.lua`, and `Placement.lua`.

## Proposal

Add one `POSITION` schema and `Position` type, and spread its shape into each schema that has `x` and `y`. The fields stay flat, so the JSON that the model reads and the Lua that writes it don't change. The action functions take a `Position` and pass `x` and `y` to the Lua call as separate numbers.

Then give a nested object a name when its shape appears twice or a function takes it. Leave every other nested object inline.

The Lua keeps separate `x` and `y` arguments, because the game's API and the FireTuner call strings use numbers. One Lua helper replaces the five hand-built position tables.

## Tasks

1. **Position schema.** Add `POSITION`, a schema of `x` and `y`, and its `Position` type to `src/schemas.ts`, next to `CITY_ID`. Commit: `refactor(core): add a shared position schema`.
2. **City state.** Spread `POSITION.shape` into the city and district schemas in `state/cities.ts`. Commit: `refactor(core): use the position schema in the city state`.
3. **Rival state.** Spread it into the two schemas in `state/rivals.ts`. Commit: `refactor(core): use the position schema in the rival state`.
4. **Tile state.** Spread it into the tile schema in `state/tiles.ts`. Commit: `refactor(core): use the position schema in the tile state`.
5. **Unit state.** Spread it into the unit schema in `state/units.ts`. Commit: `refactor(core): use the position schema in the unit state`.
6. **Artifact choices.** Spread it into the schema in `choices/artifacts.ts`. Commit: `refactor(core): use the position schema in the artifact choices`.
7. **Captured city choices.** Spread it into the schema in `choices/captured-cities.ts`. Commit: `refactor(core): use the position schema in the captured city choices`.
8. **Purchase choices.** Extend `TILE_PURCHASE` in `choices/purchases.ts` with `POSITION.shape`. Commit: `refactor(core): use the position schema in the purchase choices`.
9. **Placement.** Spread it into the schema in `placement/placement.ts`. Commit: `refactor(core): use the position schema in the placement`.
10. **Unit actions.** Make `moveUnit(client, playerID, unitID, position)` and the `UnitOrder` union take a `Position`, and update their tests. Commit: `refactor(core): pass a position to the unit actions`.
11. **City actions.** Make `purchaseTile` and `cityAttack` take a `Position`, and make `setProduction` take `tile?: Position`. Update their tests. Commit: `refactor(core): pass a position to the city actions`.
12. **Lua position helper.** Add `SentientSystems_GetPosition(plot)`, which returns `{ x, y }`, to `SentientSystemsCore_Common.lua`, and use it in the five places that build the table by hand. Commit: `refactor(core): share one Lua position helper`.
13. **Nested object list.** List every inline nested object in `packages/core/bridge/src/`, including the objects written over several lines. Mark the ones that get a name by the rule in `## Proposal`, and add a task here for each file that changes. Commit: `docs: list the nested objects to name`.
14. **Player balances.** Name the `{ balance, perTurn }` shape in `state/player.ts`, and use it for `faith` and `favor`. Commit: `refactor(core): name the player balance schema`.

## Done when

`Position` has one definition, and the action functions take it and the city references in place of loose values. No inline nested object in `packages/core/bridge/src/` appears twice or is passed to a function.

No Lua script builds a position table by hand. The bridge tests, the Lua tests, and coverage pass.
