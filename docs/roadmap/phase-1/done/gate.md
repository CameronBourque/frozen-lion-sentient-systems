# Phase 1: Claude Code gate

The finished step of [phase 1](../README.md) that played the game from Claude Code through the MCP server. The index is in [README.md](README.md).

## Claude Code gate

Pull request: docs: record phase 1 results. Each fix it found merged first in its own `fix:` or `feat:` pull request.

Claude Code played 10 turns of the smoke test preset through the MCP server, with only a prompt at the start of each turn, a `reason` on every action, and no `ERROR` lines. It took two runs. The first found seven problems, and the second passed after the fixes for six of them.

- Both runs, their prompts and setup, the calls per turn, the failures, and the pull request for each problem, in [findings/agent-runs.md](../../../findings/agent-runs.md).
- The route check and moves through unrevealed tiles, in [findings/actions/move-routes.md](../../../findings/actions/move-routes.md).
- The character classes of Lua patterns, in [findings/lua/patterns.md](../../../findings/lua/patterns.md).
- Village rewards, in [findings/state/village-rewards.md](../../../findings/state/village-rewards.md).
- Map coordinates and neighbours, in [findings/state/map-coordinates.md](../../../findings/state/map-coordinates.md).

Each pull request committed the regenerated tool reference itself, so the [tool reference](mcp-server.md#tool-reference) workflow found the page current every time, and its commit with the release app token hasn't run yet.
