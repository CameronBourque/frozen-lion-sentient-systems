# Lua states

Status: open. The `InGame` probe, the core mod's own states, their Lua version and errors, and a move requested from the core mod's UI state are confirmed in a running game on Windows. The rest is partly confirmed from game files.

Civ VI runs Lua in separate states. Gameplay scripts and UI scripts have different APIs. Which states exist, and how the list changes over a session, is in [state-list.md](state-list.md).

## Questions

1. Can a UI state read data from a gameplay state, and the other way around? Through what: `ExposedMembers`, `LuaEvents`, or properties?


## What we know now

### Two script types

| Script type | How a mod adds it | Example in the game files | Status |
| --- | --- | --- | --- |
| Gameplay script | `<AddGameplayScripts>` in `.modinfo` | `DLC/AlexanderScenario/AlexanderScenario.modinfo`, line 59 | Confirmed |
| UI script | `<AddUserInterfaces>` in `.modinfo`, with `<Context>InGame</Context>`. The action lists only the XML file, and the game loads the Lua file with the same name | `Base/Assets/UI/*.lua`, each with a matching `.xml` | Confirmed with the core mod on Windows, 2026-10-22 |

### Turn events differ by script type

| Event | Used in | Example | Status |
| --- | --- | --- | --- |
| `GameEvents.PlayerTurnStarted` | Gameplay scripts | `DLC/AlexanderScenario/Scripts/AlexanderScenario.lua`, line 247. The Poland, Vikings, and Indonesia–Khmer scenarios use it too | Confirmed |
| `Events.PlayerTurnActivated` | UI scripts | `Base/Assets/UI/Automation/Automation_ObserverCamera.lua`, line 560 | Confirmed |
| `Events.LocalPlayerTurnBegin` | UI scripts | `Base/Assets/UI/ActionPanel.lua`, line 1334 | Confirmed |

The base game UI uses `Events.*`, and scenario gameplay scripts use `GameEvents.*`. In single player on Windows on 2026-10-22, `GameEvents.PlayerTurnStarted` in a gameplay script and `Events.PlayerTurnActivated` in a UI script each fired once when the human's turn started, gameplay first. The `IsHuman()` filter in each handler kept AI turns out of the print. Neither fired when a save loaded. The first signal came when the player ended a turn and the next one started. In hotseat, a load does start the first human's turn: `Events.PlayerTurnActivated` fired for player 0 right after the pass screen, with no turn ended first.

Turns run one player at a time. An unfiltered print with the time, from `Events.PlayerTurnActivated` and `Events.PlayerTurnDeactivated`, showed this order each round. The humans went first, and each turn ended before the next started. Then every other player went in ID order, ending with 62 and 63. In `InGame`, `PlayerConfigurations[id]:GetCivilizationTypeName()` returned `CIVILIZATION_FREE_CITIES` for 62 and `CIVILIZATION_BARBARIAN` for 63. In these games, which were a few turns from a fresh start, each of those turns started and ended within a second, and all of them together took 2 to 3 s. AI turns get slower as a game goes on, because the AI has more to do. `IsTurnActive()` was true for each player inside its own activation event. Confirmed in single player and in hotseat on Windows on 2026-10-22, with about 30 players.

### Where actions can come from

The UI moves units with `UnitManager.RequestOperation` and ends turns with `UI.RequestAction`. See [game-api.md](game-api.md). These are request functions. The engine checks each action and applies it only if it is legal. The design requires this path. See [design/core/in-game-lua.md](../design/core/in-game-lua.md).

The core mod's own UI state has `UnitManager.RequestOperation` and `UI.RequestAction`. See [the core mod's states](#the-core-mods-states). A move requested there takes effect. The bridge sent `RequestOperation` to `SentientSystemsCore_UI`, the unit moved one tile on the map, and `GameCore_Tuner` read its new position 1 s later. Confirmed in single player on Windows on 2026-10-23. The calls are in [game-api.md](game-api.md#moving-a-unit).

The game's Lua files never call `UnitManager.MoveUnit`, so don't rely on it. Checked on 2026-10-16. Gameplay scenario scripts do use `UnitManager.InitUnit` and `UnitManager.PlaceUnit`, for example in `DLC/VikingsScenario/Scripts/VikingScenario.lua`.

### State names from other projects

Two community projects name the states they use. Both states appear in the [Windows state list](state-list.md#lua-state-list). Their uses are unconfirmed on Windows. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) for the projects.

| State | Use | Source |
| --- | --- | --- |
| `GameCore_Tuner` | Read-only gameplay state. civ6-logger uses it for almost all reads | [civ6-logger ARCHITECTURE.md](https://github.com/PatrickJYKang/civ6-logger/blob/c21795250050447c89d42858afdf3decbac49bd8/docs/ARCHITECTURE.md), "Two ports, and which Lua state to use" |
| `InGame` | UI state. civ6-logger uses it for getters that `GameCore_Tuner` lacks, such as the current government. civ6-mcp sends its commands to it | civ6-logger, same section. [civ6-mcp README](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a), "How it works" |

civ6-mcp sends commands to `InGame`, which matches the assumption that the action API runs in a UI state.

### The core mod's states

| Item | Value | Status |
| --- | --- | --- |
| State names | Each script gets its own state, named after its file. The UI script `SentientSystemsCore_UI.lua` runs in `SentientSystemsCore_UI`, and `ContextPtr:GetID()` returns that name. A gameplay script `SentientSystemsCore_Gameplay.lua` ran in `SentientSystemsCore_Gameplay`. The tuner list and `Lua.log` both use these names | Confirmed |
| Globals | Two files in one `AddGameplayScripts` action don't share globals. A global set in the first read as `nil` in the second | Confirmed |
| Shared files | A file listed in `ImportFiles` loads into a state with `include("SentientSystemsCore_Tag")`, the file name without its extension. It worked in a gameplay state and in a UI state. `include` finds a file by name among the imported files of every enabled mod, so a generic name such as `Version` can load another mod's file | Confirmed |
| Calls from the tuner | The tuner can call the mod's global functions, such as `SentientSystems_Print` and `SentientSystems_GetVersion`, in the mod's gameplay and UI states | Confirmed |
| Request functions | In `SentientSystemsCore_UI`, `type(UnitManager.RequestOperation)` and `type(UI.RequestAction)` are both `function` | Confirmed |
| Lua version | `_VERSION` in `SentientSystemsCore_UI` is `2013.2.0 r13768`, a Havok Script version | Confirmed |
| `debug` library | `type(debug)` in `SentientSystemsCore_UI` is `nil` | Confirmed |
| Errors in `pcall` | An error from `error("text")` or a runtime error, caught by `pcall` in `SentientSystemsCore_UI`, has a message with the error, then `stack traceback:` and one line for each call. Errors that reach the tuner have the same form. See [tuner-commands.md](tuner-commands.md#what-we-know-now). An error raised with a table, such as `error({})`, has no trace | Confirmed |
| Paths in errors | An error in a mod file names the file by its full path, such as `C:\Users\<name>\Documents\My Games\Sid Meier's Civilization VI\Mods\SentientSystemsCore\UI\SentientSystemsCore_UI.lua:38`. The path holds the user's name | Confirmed |

The first five rows were checked on Windows on 2026-10-22, and the last four on 2026-10-23.

## Method

1. Connect FireTuner to a running game.
2. Run the same probe in each relevant state:

   ```lua
   print(type(UnitManager.RequestOperation), type(UI), type(UI and UI.RequestAction), type(Game.GetLocalPlayer))
   ```

3. Load the core mod and check which new states appear.
4. To check the Lua version and errors, run these in `SentientSystemsCore_UI`:

   ```lua
   print(_VERSION, type(debug))
   SentientSystems_CatchErrors("Probe", function() error("test") end)()
   SentientSystems_CatchErrors("Probe", function() error({}) end)()
   ```

## Results

### API probe by state

| State | `RequestOperation` | `UI` | `UI.RequestAction` | `Game.GetLocalPlayer` |
| --- | --- | --- | --- | --- |
| `InGame` | `function` | `table` | `function` | `function` |
| `SentientSystemsCore_UI` | `function` | Not checked | `function` | Not checked |

Date checked: game files on 2026-10-16. Running game on Windows: 2026-10-22, and the move, the Lua version, and the errors from the core mod's UI state on 2026-10-23.
