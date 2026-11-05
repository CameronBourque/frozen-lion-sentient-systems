# Core mod

The core mod is core's in-game Lua. It signals turns, builds each player's view of the game, runs actions through the game's own request functions, and answers Civilopedia lookups. [findings/lua/contexts.md](../../../findings/lua/contexts.md) tracks which Lua state each part runs in.

| File | Covers |
| --- | --- |
| [lines.md](lines.md) | Tagged lines, turn events, resync, the load line and load signal, errors, and the version report |
| [json.md](json.md) | The JSON encoder and the stash |
| [state.md](state.md) | The state serializer and `SentientSystems_GetState` |
| [choices.md](choices.md) | The choices and the placement tiles |
| [trees.md](trees.md) | The tech, civic, and governor trees |
| [actions.md](actions.md) | The action API |

## Checkpoint ID

A gameplay script writes the checkpoint ID described in [memory.md](../../memory.md#checkpoint-ids).

## Civilopedia lookup

It queries the `GameInfo` tables and localized text at runtime, so DLC and other mods are included. It also reads the Civilopedia's Concepts section for general rules such as movement, combat, and terrain.

## JSON shapes

The zod schemas in `packages/core/bridge/src/` are the only home of the JSON shapes. A field whose name doesn't say what it means gets a `.describe()` note.

`z.toJSONSchema()` carries the `.describe()` notes, so the [MCP server step](../../../roadmap/phase-1/mcp-server.md) can give them to the model if it adds output schemas to the tools. That step decides it, because output schemas add tokens to every request.

## Decisions

| Decision | Reason |
| --- | --- |
| Game facts come from the Civilopedia at runtime | It includes DLC and mods with no upkeep |
| The core mod has no gameplay script until checkpoint IDs need one | Nothing else needs a gameplay state yet |
| Each mod file name starts with the mod's prefix, such as `SentientSystemsCore_` | `include` finds a file by name among every enabled mod's imported files, so a generic name can load another mod's file |
| The zod schemas are the only home of the JSON shapes, and no reference is generated from them | The shapes were once in up to five places, and a copy that drifted misled the next reader. Each schema file is 13 to 85 lines, so an agent reads the one it needs. A generated file would be large |
