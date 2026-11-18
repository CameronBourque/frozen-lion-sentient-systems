# Claude Code gate

Pass the gate: Claude Code plays 10 turns of a single-player game through the MCP server, with you prompting each turn. Part of [phase 1](README.md).

## Tasks

1. **Play.** Start a single-player game with the settings of the smoke test preset in [testing.md](../../design/testing.md#presets), and open Claude Code at the repo root, so it starts the server from `.mcp.json`.

   At the start of each turn, tell Claude Code that it's its turn. It reads the state, acts, and calls `end_turn`. Play 10 turns. Commit nothing yet.
2. **Fix.** For each tool call that fails when it should work, each `ERROR` line, and each popup that needs a click, fix the cause in its own `fix:` PR. Play again from the save before the bug. Commit: `fix(core): <the bug>`, one per bug.
3. **Results.** Record the run: the turns played, the tool calls per turn, the calls that failed and why, and what Claude Code had to ask or guess. Commit: `docs: record the Claude Code gate`.

## Done when

Claude Code plays 10 turns in a row with only a prompt at the start of each turn. Every action has a `reason`, and the log has no `ERROR` lines.

## Record

- The run, in a new finding, `docs/findings/agent-runs.md*`. Add it to the [findings index](../../findings/README.md).
- Any tool description that misled Claude Code, fixed in its tool, so the [tool reference](tool-reference.md) updates.
