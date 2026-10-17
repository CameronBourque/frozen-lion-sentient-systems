# Findings

What we learn about Civ VI, FireTuner, and our tools while we build the bridge. Each file covers one topic. Statuses, history, and file structure follow [rules/docs.md](../rules/docs.md#findings).

| File | Topic | Status |
| --- | --- | --- |
| [tuner-protocol.md](tuner-protocol.md) | FireTuner port, frame format, and message types | Open. Described by community projects, not captured yet |
| [tuner-setup.md](tuner-setup.md) | Turning on the tuner: the menu toggle, the SDK, and achievements | Open. Described by civ6-mcp, not tested |
| [lua-contexts.md](lua-contexts.md) | Lua states and what each one can call | Open. Partly confirmed from game files |
| [game-api.md](game-api.md) | Game calls for cities, units, turns, and properties | Open. Partly confirmed from game files |
| [build-tooling.md](build-tooling.md) | The single-executable build tool | Open. No choice yet |
| [multiplayer.md](multiplayer.md) | Whether the tuner works in an online game | Open. Not tested |

## Local paths

These paths are from Cameron's machine. Other machines may differ.

| Item | Path |
| --- | --- |
| `AppOptions.txt` | `%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VI\AppOptions.txt` |
| Game install | `E:\SteamLibrary\steamapps\common\Sid Meier's Civilization VI\` |
| Game executables | `<game>\Base\Binaries\Win64Steam\CivilizationVI.exe` and `CivilizationVI_DX12.exe` |
| Game UI Lua | `<game>\Base\Assets\UI\` |
| DLC and scenario Lua and `.modinfo` files | `<game>\DLC\` |
| SDK and FireTuner | `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VI SDK\FireTuner\FireTuner2.exe` |
| User mods folder | `%USERPROFILE%\OneDrive\Documents\My Games\Sid Meier's Civilization VI\Mods\` |

`AppOptions.txt` is not in the Documents folder. The Documents folder holds logs, saves, and mods.
