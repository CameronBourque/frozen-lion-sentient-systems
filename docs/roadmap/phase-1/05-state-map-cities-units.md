# Step 5: State: map, cities, and units

Build the first half of the state serializer: one player's cities, units, and the tiles that player has revealed, from that player's visibility data. Part of [phase 1](README.md).

## Tasks

Tasks 1, 4, 5, and 6 need the game but no new mod code, so you can run them in one session. Each Lua task from task 8 on adds its own tests in `packages/core/mod/test/`.

1. **Lua dialect.** From the tuner, run these in `SentientSystemsCore_UI`, then in Lua 5.1, and record where the results differ: `tostring(3.0)`, `tostring(7 / 2)`, `tostring(2 ^ 53)`, `tostring(1 / 0)`, `string.format("%d", 3.5)`, `type(math.type)`, `type(unpack)`, `type(table.unpack)`, `type(utf8)`, and `type(table.move)`. Commit: `docs: record the core mod's Lua dialect`.
2. **Lua tests.** Install Lua 5.1 and LuaRocks, then run `luarocks install busted`. Add `npm run test:lua`, which runs busted on `packages/core/mod/test/`. Add a test helper that loads a mod file with a fake `include`. Test `Scripts/SentientSystemsCore_Tag.lua` with it. Add a CI job that installs Lua 5.1 and runs `npm run test:lua`. Commit: `test(core): run the core mod's Lua tests with busted`.
3. **Lua coverage.** Run `luarocks install luacov`. Make `npm run coverage` also run busted with luacov, and fail when the Lua line coverage is below 98%. Add the Lua coverage table to the CI job summary. Commit: `test(core): measure the core mod's Lua coverage`.
4. **Large print.** Print a 1 MB string from `SentientSystemsCore_UI`, and check that the bridge reads it whole. Record the time it takes. Commit: `docs: record a large print from the core mod's UI state`.
5. **Fogged tiles.** Find what a player knows about a tile under fog, and which calls give the core mod that knowledge.
   - Read `PlotToolTip.lua` and the map's fog drawing in `<game>\Base\Assets\UI\` to find what the game shows for a fogged tile.
   - List the methods of `PlayersVisibility[playerID]`.
   - For a tile under fog, compare the plot calls, such as `GetImprovementType` and `GetOwner`, with what the tooltip shows. Check whether the plot calls return the tile's contents now or what the player last saw.

   Commit: `docs: record what the game shows for fogged tiles`.
6. **Map reveal.** Reveal the map through FireTuner. Check whether `PlayersVisibility[playerID]` returns the same values before and after the reveal. Commit: `docs: record how the FireTuner map reveal works`.
7. **Review.** Rewrite tasks 15 and 16 and the "Done when" from what tasks 5 and 6 found. Commit: `docs: plan the tile tasks from the fog findings`.
8. **JSON in Lua.** Add `Scripts/SentientSystemsCore_Json.lua` with a small encoder for tables, strings, numbers, and booleans. Escape each newline in a string, and add no line breaks between values, so the output is one line. Add `SentientSystems_PrintChunks(text)`, which prints the text in pieces of 1,000,000 characters, because a longer print gets no reply. See the print size limit in [tuner-commands.md](../../findings/tuner-commands.md#what-we-know-now). Test the encoder against tables with nested lists, quotes, and newlines. Test `SentientSystems_PrintChunks` with text shorter than one piece, exactly one piece, and longer than one piece. Commit: `feat(core): add a JSON encoder to the core mod`.
9. **Cities.** Add `SentientSystems_GetState(playerID)`, which returns JSON with each city's ID, name, position, and population. Add a fake game for the tests. Commit: `feat(core): add cities to the state`.
10. **City production.** Add each city's current production with turns left, and its yields. Commit: `feat(core): add city production and yields to the state`.
11. **Districts.** Add each city's districts. Commit: `feat(core): add city districts to the state`.
12. **Units.** Add each unit's ID, type, position, moves left, and health. Skip units at X `-9999`, as civ6-mcp does in [game-api.md](../../findings/game-api.md#units). Commit: `feat(core): add units to the state`.
13. **Promotions.** Add each unit's available promotions. Commit: `feat(core): add unit promotions to the state`.
14. **Tiles.** Add each tile that `PlayersVisibility[playerID]` has revealed, with terrain, feature, and whether the tile is visible now. Never read what the screen shows. Commit: `feat(core): add revealed tiles to the state`.
15. **Resources.** Add each tile's resource, only when the player's techs reveal it. Commit: `feat(core): add visible resources to tiles`.
16. **Improvements and owners.** Add each tile's improvement and owner. Commit: `feat(core): add improvements and owners to tiles`.
17. **Rival cities.** Add rival cities only on tiles that are visible now. Commit: `feat(core): add visible rival cities to the state`.
18. **Rival units.** Add rival units only on tiles that are visible now. Skip units the player can't see on a visible tile, such as stealth units. Commit: `feat(core): add visible rival units to the state`.
19. **Bridge.** Add `src/state.ts`, which sends `SentientSystems_PrintChunks(SentientSystems_GetState(<playerID>))` to `SentientSystemsCore_UI`. It joins the reply's lines with no separator, checks the JSON with a `zod` schema, and returns a typed state. The encoder from task 8 escapes each newline, so the joined lines are the exact JSON. Commit: `feat(core): read the state in the bridge`.
20. **State script.** Add `npm run state`, which prints the state and its size in bytes. Commit: `feat(core): add the state script`.

## Done when

All of these hold in a running game:

- `npm run state` prints the player's cities and units with the values the game shows.
- A tile under fog has its last-seen contents, and a tile never revealed is missing.
- With the map revealed through FireTuner, the state is the same as without it.

## Record

- The Lua dialect from task 1, in [lua-contexts.md](../../findings/lua-contexts.md#the-core-mods-states).
- The Lua test runner, its install, and Lua coverage, in place of the last bullet under **Lint and test** in [code.md](../../rules/code.md#lint-and-test).
- How the tuner carries a large print from the core mod's UI state, in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes).
- Each state call, its Lua state, and its result, and the fog and map reveal results, in a new finding, `findings/game-state.md`. Add it to the [findings index](../../findings/README.md).
- The state format, in [in-game-lua.md](../../design/core/in-game-lua.md).
