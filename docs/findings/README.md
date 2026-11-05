# Findings

What we learn about Civ VI, FireTuner, and our tools while we build the bridge. Each folder covers one topic, and each file in it covers one question. Each file's status line says how settled it is. Statuses, history, and file structure follow [rules/docs.md](../rules/docs.md#findings).

| Folder | Topic |
| --- | --- |
| [tuner/](tuner/README.md) | How the bridge reaches the game: turning on the tuner, the wire protocol, how commands run, and what the tuner can do in hotseat and online games. |
| [lua/](lua/README.md) | The Lua states in the running game, what each one can call, and how the list changes. |
| [actions/](actions/README.md) | The game calls the action API wraps, with the reasons their checks give. |
| [state/](state/README.md) | The game calls the state serializer uses, and what a player can know about each tile. |
| [choices/](choices/README.md) | The game calls the choices use to list each choice's legal options, as the game's screens list them. |

Two files sit at the top, because each has no topic folder yet:

| File | Topic |
| --- | --- |
| [game-api.md](game-api.md) | Game calls for cities, units, turns, and properties |
| [build-tooling.md](build-tooling.md) | The single-executable build tool |

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
| SDK and FireTuner | `E:\SteamLibrary\steamapps\common\Sid Meier's Civilization VI SDK\FireTuner\FireTuner2.exe` |
| FireTuner panels, such as `Map.ltp` | `<game>\Debug\` |
| User mods folder | `%USERPROFILE%\OneDrive\Documents\My Games\Sid Meier's Civilization VI\Mods\` |

`AppOptions.txt` and the logs are not in the Documents folder. The Documents folder holds saves and mods.
