# Step 5: State: map, cities, and units

Build the first half of the state serializer: one player's cities, units, and the tiles that player has revealed, from that player's visibility data. Part of [phase 1](README.md).

## Tasks

1. **JSON in Lua.** Add `Scripts/SentientSystemsCore_Json.lua` with a small encoder for tables, strings, numbers, and booleans. Test it from the tuner against a few tables with nested lists and quotes. Commit: `feat(core): add a JSON encoder to the core mod`.
2. **Large replies.** Print a 1 MB string from `SentientSystemsCore_UI` and check that the bridge reads it whole. Record the time it takes. If a frame has a size limit, split the print into numbered lines and join them in the bridge. Commit: `docs: record how the tuner carries a large print`.
3. **Cities.** Add `SentientSystems_GetState(playerID)`, which returns JSON with each city's ID, name, position, population, current production with turns left, yields, and districts. Commit: `feat(core): add cities to the state`.
4. **Units.** Add each unit's ID, type, position, moves left, health, and promotions available. Skip units at X `-9999`, as civ6-mcp does in [game-api.md](../../findings/game-api.md#units). Commit: `feat(core): add units to the state`.
5. **Tiles.** Add each tile that `PlayersVisibility[playerID]` has revealed, with terrain, feature, resource, improvement, owner, and whether the tile is visible now. Never read what the screen shows. Commit: `feat(core): add revealed tiles to the state`.
6. **Visible rivals.** Add rival cities and units only on tiles that are visible now. Commit: `feat(core): add visible rivals to the state`.
7. **Bridge.** Add `src/state.ts`, which calls `SentientSystems_GetState`, checks the JSON with a `zod` schema, and returns a typed state. Add `npm run state`, which prints the state and its size in bytes. Commit: `feat(core): read the state in the bridge`.

## Done when

All of these hold in a running game:

- `npm run state` prints the player's cities and units with the values the game shows.
- A tile under fog has its last-seen contents, and a tile never revealed is missing.
- With the map revealed through FireTuner, the state is the same as without it.

## Record

- Each call, its Lua state, and its result, in a new finding, `findings/game-state.md`. Add it to the [findings index](../../findings/README.md).
- How the tuner carries a large print, in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes).
- The state format, in [in-game-lua.md](../../design/core/in-game-lua.md).
