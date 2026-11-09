# Nested objects

A pair of values that always go together, such as a tile's `x` and `y`, is written out inline in schemas and function signatures, and objects nest inside objects with no name, so the same idea has many spellings and the bridge has no type to pass around.

## Now

The counts come from a scan of `packages/core/bridge/src/` and `packages/core/mod/Scripts/`.

**Positions.** A tile position, `x` and `y`, is declared inline in 10 schemas: `choices/artifacts.ts`, `choices/captured-cities.ts`, `choices/purchases.ts`, `placement/placement.ts`, `state/cities.ts` (twice), `state/rivals.ts` (twice), `state/tiles.ts`, and `state/units.ts`.

None of these `x` and `y` fields has its own description.

It is also a loose pair in function signatures: `moveUnit` in `actions/units.ts`, and `cityAttack` and `purchaseTile` in `actions/cities.ts`. `setProduction` takes it as an inline `{ x: number; y: number }`.

The `UnitOrder` type in `actions/units.ts` repeats the pair in its union. Only the bridge tests call these functions.

**References.** A city named by `owner` and `id` is `CITY_ID` in `src/schemas.ts`, and `CITY_REF` adds its name. Every schema uses them. A unit is named by its ID alone, because the player only acts on their own units.

**Objects with objects inside.** 86 schema fields hold an inline `z.object`, directly or in an array, in 30 files. The most are in `state/cities.ts` (11), `state/diplomacy.ts` (11), and `state/era.ts` (6).

Examples are `moves: z.object({ left, max })` in `state/units.ts` and `turnsUntilNext: z.object({ min, max })` in `state/era.ts`. No function in the bridge takes a nested object.

An inline object has no name, so a reader can't tell whether two of them are the same idea, and a function that takes one has to spell its shape out again.

Six key sets appear more than once with at least one of them inline. This table lists them, with whether the copies are the same idea.

| Keys | Where | Same idea |
| --- | --- | --- |
| `balance`, `perTurn` | `gold`, `faith`, and `favor` in `state/player.ts` | Yes. Only `gold` describes its fields |
| `percent`, `trigger`, `triggered` | `boost` in `choices/research.ts` and in `trees/research.ts` | Yes. The tree's description says it works as in the choice |
| `food`, `production`, `gold`, `science`, `culture`, `faith` | `yields` in `state/cities.ts`, and `YIELDS` in `src/schemas.ts` | Yes. The city's fields are required, and the fields of `YIELDS` are optional |
| `type`, `amount` | `yields` in `choices/trade-routes.ts`, and `YIELD` in `state/great-works.ts` | Yes. The trade route rounds its amount to one decimal |
| `type`, `amount` | `resources` in `state/envoys.ts` | No. It holds a resource, not a yield |
| `A`, `B` | `options` and `votes` in `choices/world-congress.ts` | No. One holds the text of each outcome, the other the votes |
| `type`, `name`, `description` | `options` in `choices/dedications.ts`, and `agendas.list` in `state/diplomacy.ts` | No. One is a dedication, the other an agenda |

Every other nested object appears once.

**Lua.** The Lua functions take a position as separate `x` and `y` arguments, as the game's own calls do, such as `Map.GetPlot(x, y)`.

Five places build the table `{ x = plot:GetX(), y = plot:GetY() }` by hand: `ActionsUnitAttacks.lua` (twice), `ActionsUnitTileOrders.lua`, `ChoicesPurchases.lua`, and `Placement.lua`.

## Proposal

Add one `POSITION` schema and `Position` type, and spread its shape into each schema that has `x` and `y`. The fields stay flat, so the JSON that the model reads and the Lua that writes it don't change. The action functions take a `Position` and pass `x` and `y` to the Lua call as separate numbers.

Then give a nested object a name when the same idea appears twice or a function takes it. Two objects with the same keys and different meanings stay inline, and so does every object that appears once. A shared name lives in `src/schemas.ts` when two files use it.

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
14. **Player balances.** Name the `{ balance, perTurn }` shape in `state/player.ts`, and use it for `gold`, `faith`, and `favor`. `gold` extends it with its own descriptions. Commit: `refactor(core): name the player balance schema`.
15. **Boosts.** Add `BOOST` to `src/schemas.ts`, with the descriptions from `choices/research.ts`, and use it in that file and in `trees/research.ts`. Commit: `refactor(core): share one boost schema`.
16. **City yields.** Make `yields` in `state/cities.ts` use `YIELDS.required()`. Commit: `refactor(core): use the yields schema in the city state`.
17. **Yield amounts.** Move `YIELD` from `state/great-works.ts` to `src/schemas.ts` as `YIELD_AMOUNT`, and use it in `choices/trade-routes.ts`, which extends it with its rounding. Commit: `refactor(core): share one yield amount schema`.

## Done when

`Position` has one definition, and the action functions take it and the city references in place of loose values. No idea in `packages/core/bridge/src/` is written out as an inline nested object twice, and no function takes an inline nested object.

No Lua script builds a position table by hand. The bridge tests, the Lua tests, and coverage pass.
