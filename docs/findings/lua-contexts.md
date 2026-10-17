# Lua states

Status: open. Partly confirmed from game files.

Civ VI runs Lua in separate states. Gameplay scripts and UI scripts have different APIs. The FireTuner state list shows which states exist in a running game.

## Questions

1. Which Lua states does FireTuner list in a running game? Do the names stay the same between loads?
2. Which state can issue player actions through the UI's request functions?
3. Can a UI state read data from a gameplay state, and the other way around? Through what: `ExposedMembers`, `LuaEvents`, or properties?
4. Do the core mod's own states show in the tuner list under predictable names, and can the tuner call the mod's global functions in them?
5. Which state fires the turn-start event reliably for each human slot, including in hotseat?
6. Does a UI state see globals from `Version.lua`, or does it need its own `include`?

## What we know now

### Two script types

| Script type | How a mod adds it | Example in the game files | Status |
| --- | --- | --- | --- |
| Gameplay script | `<AddGameplayScripts>` in `.modinfo` | `DLC/AlexanderScenario/AlexanderScenario.modinfo`, line 59 | Confirmed |
| UI script | `<AddUserInterfaces>` in `.modinfo`, with a Lua file and an XML file | `Base/Assets/UI/*.lua`, each with a matching `.xml` | The files are confirmed. The `.modinfo` action is unconfirmed |

### Turn events differ by script type

| Event | Used in | Example | Status |
| --- | --- | --- | --- |
| `GameEvents.PlayerTurnStarted` | Gameplay scripts | `DLC/AlexanderScenario/Scripts/AlexanderScenario.lua`, line 247. The Poland, Vikings, and Indonesia–Khmer scenarios use it too | Confirmed |
| `Events.PlayerTurnActivated` | UI scripts | `Base/Assets/UI/Automation/Automation_ObserverCamera.lua`, line 560 | Confirmed |
| `Events.LocalPlayerTurnBegin` | UI scripts | `Base/Assets/UI/ActionPanel.lua`, line 1334 | Confirmed |

The base game UI uses `Events.*`, and scenario gameplay scripts use `GameEvents.*`. The core mod's turn signal should use the event that belongs to the state it runs in.

### Where actions can come from

The UI moves units with `UnitManager.RequestOperation` and ends turns with `UI.RequestAction`. See [game-api.md](game-api.md). These are request functions. The engine checks each action and applies it only if it is legal. The design requires this path. See [design/core/in-game-lua.md](../design/core/in-game-lua.md).

We assume, without confirmation yet, that the core mod's action API runs in a UI state that the mod adds. The phase 0 gate tests it.

An earlier note said gameplay scripts move units with `UnitManager.MoveUnit`. On 2026-10-16, a search of the game's Lua files found no use of that function, so treat it as unverified. Gameplay scenario scripts do use `UnitManager.InitUnit` and `UnitManager.PlaceUnit`, for example in `DLC/VikingsScenario/Scripts/VikingScenario.lua`.

### State names from other projects

Two community projects name the states they use. Neither is confirmed on Windows. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) for the projects.

| State | Use | Source |
| --- | --- | --- |
| `GameCore_Tuner` | Read-only gameplay state. civ6-logger uses it for almost all reads | [civ6-logger ARCHITECTURE.md](https://github.com/PatrickJYKang/civ6-logger/blob/c21795250050447c89d42858afdf3decbac49bd8/docs/ARCHITECTURE.md), "Two ports, and which Lua state to use" |
| `InGame` | UI state. civ6-logger uses it for getters that `GameCore_Tuner` lacks, such as the current government. civ6-mcp sends its commands to it | civ6-logger, same section. [civ6-mcp README](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a), "How it works" |

civ6-mcp sends commands to `InGame`, which matches the assumption that the action API runs in a UI state.

## Method

1. Connect FireTuner to a running game and copy the full state list here.
2. Run the same probe in each relevant state:

   ```lua
   print(type(UnitManager.RequestOperation), type(UI), type(UI and UI.RequestAction), type(Game.GetLocalPlayer))
   ```

3. Load the core mod and check which new states appear.

## Results

### Lua state list

Not captured yet.

### API probe by state

| State | `RequestOperation` | `UI` | `UI.RequestAction` | `Game.GetLocalPlayer` |
| --- | --- | --- | --- | --- |
| | | | | |

Date checked: game files on 2026-10-16. Running game: not yet.
