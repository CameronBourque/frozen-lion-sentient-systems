# Core

Core is the core mod and the bridge. The core mod is the in-game Lua, and the bridge is the external TypeScript program. They ship together with one shared version. Core is the only code that talks to the game (see [../architecture.md](../architecture.md#core-boundary)).

| File | Covers |
| --- | --- |
| [in-game-lua.md](in-game-lua.md) | The core mod: turn events, the state serializer, the action API, checkpoint IDs, and Civilopedia lookup |
| [bridge.md](bridge.md) | The bridge: tuner client, tagged lines, resync, version check, MCP server, model client, memory store |
| [logs.md](logs.md) | The bridge's log records, levels, and log files |
| [settings.md](settings.md) | The bridge's config file |
| [toolchain.md](toolchain.md) | How the bridge is built, checked, and released, and the tool reference workflow |

Code: [packages/core/](../../../packages/core/README.md).
