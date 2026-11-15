# Core mod

The core mod is core's in-game Lua. It signals turns, builds each player's view of the game, runs actions through the game's own request functions, and answers Civilopedia lookups. [findings/lua/contexts.md](../../../findings/lua/contexts.md) tracks which Lua state each part runs in.

| File | Covers |
| --- | --- |
| [lines.md](lines.md) | Tagged lines, turn events, resync, the load line and load signal, errors, and the version report |
| [json.md](json.md) | The JSON encoder and the stash |
| [state.md](state.md) | The state serializer and `SentientSystems_GetState` |
| [choices.md](choices.md) | The choices and the placement tiles |
| [trees.md](trees.md) | The tech, civic, and governor trees |
| [actions/](actions/README.md) | The action API |

## Checkpoint ID

A gameplay script writes the checkpoint ID described in [memory.md](../../memory.md#checkpoint-ids).

## Civilopedia lookup

It queries the `GameInfo` tables and localized text at runtime, so DLC and other mods are included. It also reads the Civilopedia's Concepts section for general rules such as movement, combat, and terrain.

## Popups

An agent player can't see the screen, so the core mod closes each popup that waits for a click when it opens for an agent player.

`SENTIENTSYSTEMS_POPUPS` in `SentientSystemsCore_Popups.lua` lists each popup by its context's name, with the steps of its `Close` that differ. `SentientSystemsCore_UI.lua` closes it from its `<name>_Shown` event.

A popup's lock holds the engine's event queue, so requests and the AI turns wait until it closes. The close repeats the popup's own `Close`, and releases the event ID twice: once for its own reference, and once for the popup's lock. See [findings/actions/end-turn.md](../../../findings/actions/end-turn.md#with-the-wonder-built-popup-up).

A popup's closed signal waits for `Events.GameCoreEventPublishComplete`, so it comes after every listener of the open signal. `InGame.lua` hides the interface on the open signal and shows it again on the closed one.

A meteor shower or a comet strike, in the apocalypse mode, lets its animation drive its popup. The popup opens on `RandomEventStarted` and locks again on `RandomEventOccurred`, so the core mod releases that second lock at the end of the batch too. See [findings/actions/popups.md](../../../findings/actions/popups.md#natural-disaster-popup).

The popup's own manager still counts itself locked after the close. Later popups of that kind go into its queue and never show, so they never hold the queue. A human who took over the slot in the same session would see none of them.

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
| Game text goes through the helpers in `SentientSystemsCore_Text.lua` | The game's text carries font icons and color tags that tell an agent nothing. The helpers name or drop each icon, drop the color tags, and turn `[NEWLINE]` into a new line, so every section reads the same |
| A helper that several scripts share lives in the smallest file that every caller loads: `SentientSystemsCore_Math.lua` for rounding, and `SentientSystemsCore_Lookups.lua` for lookups by ID, yield names, and plot positions | A fix lands in one place, and a script loads no code it doesn't use |
| A helper that only one feature's scripts share stays in that feature's file, such as `ChoicesPurchases.lua`, and the others include it | `SentientSystemsCore_Common.lua` keeps only what every script needs to run: tagged printing, error catching, and the checked include |
| A Lua function takes a tile position as separate `x` and `y` arguments, and `SentientSystems_GetPosition` builds the position table that the JSON holds | The game's own calls, such as `Map.GetPlot(x, y)`, take separate numbers, and so do the FireTuner call strings that the bridge sends |
| The core mod closes a popup by repeating its `Close`, and doesn't replace the popup's file | Gathering Storm and other mods replace the game's UI files, so a replaced file would clash with them. The popup's `Close` is local to its context, so the core mod repeats its steps |
| Each local function name in the core mod has one definition | Two functions with one name and different bodies sent a reader to the wrong file. A name that says what the function returns, such as `GetHeldPromotions`, can't be mistaken for another |
