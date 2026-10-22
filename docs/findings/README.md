# Findings

What we learn about Civ VI, FireTuner, and our tools while we build the bridge. Each file covers one topic. Each file's status line says how settled it is. Statuses, history, and file structure follow [rules/docs.md](../rules/docs.md#findings).

| File | Topic |
| --- | --- |
| [tuner-protocol.md](tuner-protocol.md) | FireTuner port, frame format, and message types |
| [tuner-commands.md](tuner-commands.md) | How the game runs commands, what replies carry, and output order |
| [tuner-setup.md](tuner-setup.md) | Turning on the tuner: the menu toggle, the SDK, and achievements |
| [lua-contexts.md](lua-contexts.md) | Lua states and what each one can call |
| [game-api.md](game-api.md) | Game calls for cities, units, turns, and properties |
| [build-tooling.md](build-tooling.md) | The single-executable build tool |
| [multiplayer.md](multiplayer.md) | Whether the tuner works in an online game |

## Local paths

These paths are from one Windows test machine. Other machines may differ.

| Item | Path |
| --- | --- |
| `AppOptions.txt` | `%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VI\AppOptions.txt` |
| Game logs, such as `Lua.log` | `%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VI\Logs\` |
| Game install | `E:\SteamLibrary\steamapps\common\Sid Meier's Civilization VI\` |
| Game executables | `<game>\Base\Binaries\Win64Steam\CivilizationVI.exe` and `CivilizationVI_DX12.exe` |
| Game UI Lua | `<game>\Base\Assets\UI\` |
| DLC and scenario Lua and `.modinfo` files | `<game>\DLC\` |
| SDK and FireTuner | `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VI SDK\FireTuner\FireTuner2.exe` |
| User mods folder | `%USERPROFILE%\OneDrive\Documents\My Games\Sid Meier's Civilization VI\Mods\` |

`AppOptions.txt` and the logs are not in the Documents folder. The Documents folder holds saves and mods.
