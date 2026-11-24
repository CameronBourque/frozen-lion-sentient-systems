# Core

Core is the core mod and the bridge. The core mod is the in-game Lua, and the bridge is the external TypeScript program. They ship together with one shared version. Core is the only code that talks to the game (see [../architecture.md](../architecture.md#core-boundary)).

| File | Covers |
| --- | --- |
| [mod/](mod/README.md) | The core mod: turn events, the state serializer, the action API, checkpoint IDs, and Civilopedia lookup |
| [bridge.md](bridge.md) | The bridge: tuner client, tagged lines, resync, version check, MCP server, model client, memory store |
| [mcp-server.md](mcp-server.md) | How the bridge serves its tools over MCP, in process and over local HTTP |
| [model-client.md](model-client.md) | How the bridge calls a model through one interface over every provider |
| [run-modes.md](run-modes.md) | How agents reach a model: an API key, a subscription token, an agent SDK, or a CLI |
| [subscription-token.md](subscription-token.md) | How agents play on a ChatGPT plan: the browser sign-in, the token refresh, and the plan calls |
| [logs.md](logs.md) | The bridge's log records, levels, and log files |
| [settings.md](settings.md) | The bridge's config file |
| [toolchain.md](toolchain.md) | How the bridge is built, checked, and released, and the tool reference workflow |

Code: [packages/core/](../../../packages/core/README.md).
