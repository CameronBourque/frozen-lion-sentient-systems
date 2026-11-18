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
| [civilopedia.md](civilopedia.md) | The Civilopedia lookup: its index, search, and pages |

## Checkpoint ID

A gameplay script writes the checkpoint ID described in [memory.md](../../memory.md#checkpoint-ids).

## Popups

An agent player can't see the screen, so the core mod closes each popup that waits for a click when it opens for an agent player.

`SENTIENTSYSTEMS_POPUPS` in `SentientSystemsCore_Popups.lua` lists each popup by its context's name, with how it closes.

`SentientSystemsCore_UI.lua` closes each one that is open when a batch of game events ends, when a load ends, and on `Events.UIIdle`, when the historic moment popup shows a moment it held back.

A popup that holds nothing, such as the hero, Secret Society, or spy mission popup, closes by dequeuing it, with its closed signal if it has one. A screen such as the great work popup shows by unhiding its context, so the core mod hides it instead.

A popup whose own close does more names a LuaEvent that runs that close, such as the congress voting screen's, or the button that runs it, for `DoLeftClick`. The leader screen closes only while no diplomacy session is open, when it shows only the overview, as after a peace.

The wonder built, natural wonder, natural disaster, project built, and rock band movie popups hold the engine's event queue, so requests and the AI turns wait until they close.

The core mod presses each one's own `Close` button. It shows the popup's next queued one, or sends the closed signal and unlocks.

A meteor shower or a comet strike lets its animation drive its popup. The popup opens on `RandomEventStarted` and locks again on `RandomEventOccurred` only while it is still open, so a close at the end of the first batch leaves no second lock. See [findings/actions/popups.md](../../../findings/actions/popups.md#natural-disaster-popup).

The natural wonder's fly-around starts after the batch ends, and keeps the camera until it stops. So the core mod stops the camera again on the next `Events.GameCoreEventPlaybackComplete` after that popup closes. See [findings/actions/popups.md](../../../findings/actions/popups.md#natural-wonder-popup).

The unit captured message comes through the shared `InGamePopup` dialog, which also asks the player to confirm strikes and cities. So the core mod closes it only after `LuaEvents.OnRaisePopupInGame` raises `UnitCaptured`, by pressing the dialog's own button, found through `GetChildren()`.

Where the game has a switch that keeps a popup from opening, the core mod uses it instead.

When a load ends, `SentientSystemsCore_UI.lua` fires the tutorial's `LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups()` for an agent player, which turns off the tech, civic, and boost popups. See [findings/actions/popups.md](../../../findings/actions/plain-popups.md#tech-civic-and-boost-popups).

## JSON shapes

The zod schemas in `packages/core/bridge/src/` are the only home of the JSON shapes. A field whose name doesn't say what it means gets a `.describe()` note.

`z.toJSONSchema()` carries the `.describe()` notes, so the [MCP server step](../../../roadmap/phase-1/mcp-server.md) can give them to the model if it adds output schemas to the tools. That step decides it, because output schemas add tokens to every request.

## Decisions

| Decision | Reason |
| --- | --- |
| The core mod has no gameplay script until checkpoint IDs need one | Nothing else needs a gameplay state yet |
| Each mod file name starts with the mod's prefix, such as `SentientSystemsCore_` | `include` finds a file by name among every enabled mod's imported files, so a generic name can load another mod's file |
| The zod schemas are the only home of the JSON shapes, and no reference is generated from them | The shapes were once in up to five places, and a copy that drifted misled the next reader. Each schema file is 13 to 85 lines, so an agent reads the one it needs. A generated file would be large |
| Game text goes through the helpers in `SentientSystemsCore_Text.lua` | The game's text carries font icons and color tags that tell an agent nothing. The helpers name or drop each icon, drop the color tags, and turn `[NEWLINE]` into a new line, so every section reads the same |
| A helper that several scripts share lives in the smallest file that every caller loads: `SentientSystemsCore_Math.lua` for rounding, and `SentientSystemsCore_Lookups.lua` for lookups by ID, yield names, and plot positions | A fix lands in one place, and a script loads no code it doesn't use |
| A helper that only one feature's scripts share stays in that feature's file, such as `ChoicesPurchases.lua`, and the others include it | `SentientSystemsCore_Common.lua` keeps only what every script needs to run: tagged printing, error catching, and the checked include |
| A Lua function takes a tile position as separate `x` and `y` arguments, and `SentientSystems_GetPosition` builds the position table that the JSON holds | The game's own calls, such as `Map.GetPlot(x, y)`, take separate numbers, and so do the FireTuner call strings that the bridge sends |
| The core mod closes a popup through its own `Close`, and doesn't replace its file | Other mods replace the game's UI files, so a replaced file would clash. `Close` is local to its context, so the core mod presses its button or fires its LuaEvent. A copy of its steps missed the popup's lock |
| Each local function name in the core mod has one definition | Two functions with one name and different bodies sent a reader to the wrong file. A name that says what the function returns, such as `GetHeldPromotions`, can't be mistaken for another |
