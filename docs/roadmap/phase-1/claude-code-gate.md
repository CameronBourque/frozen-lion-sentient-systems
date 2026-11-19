# Claude Code gate

Pass the gate: Claude Code plays 10 turns of a single-player game through the MCP server, with you prompting each turn. Part of [phase 1](README.md).

## Tasks

1. **Play.** Start a single-player game with the settings of the smoke test preset in [testing.md](../../design/testing.md#presets), and start the bridge with `npm run mcp`. Open Claude Code at the repo root, so it connects to the bridge through `.mcp.json`.

   At the start of each turn, tell Claude Code that it's its turn. It reads the state, acts, and calls `end_turn`. Play 10 turns. Commit nothing yet.
2. **Fix.** For each tool call that fails when it should work, each `ERROR` line, and each popup that needs a click, fix the cause in its own `fix:` PR. Play again from the save before the bug. Commit: `fix(core): <the bug>`, one per bug.

   The first run, from the setup prompt on turn 1 to turn 11, needs these PRs:

   1. **End turn after a cancel.** When a queued move stops short, the game cancels the end of the turn and starts it again. `end_turn` then refuses every call as a turn already ended. Clear the request when the turn starts. Commit: `fix(core): allow end turn after the game cancels it`.
   2. **No route right after founding a city.** On turn 1, a move sent right after founding the capital was refused as having no route. For a short time the game sometimes returns no path for a tile it can reach.

      Say in the reason to try again, and delete the river debt that this explains. Commit: `fix(core): say when to retry a move with no route`.
   3. **Moves into unrevealed tiles.** A path through unrevealed tiles assumes they can be crossed. Once a revealed tile blocks it, the game keeps the move, and the unit stands still without needing orders.

      Cancel such a move when the unit's move ends and when the turn starts, add an event, show each unit's destination, and say it in the `move_unit` description. Commit: `fix(core): cancel moves whose destination can't be reached`.
   4. **Broken characters in names.** The state showed the great artist Kamāl ud-Dīn Behzād with a replacement character for each `ā`, while `ī` came through. Find where the text breaks, and fix it. Commit: `fix(core): keep the characters of localized text`.
   5. **Tribal village rewards.** The state's `events` holds no tribal village reward, so the player can't tell what a village gave. Add the reward to `events`. Commit: `feat(core): add tribal village rewards to the events`.

   Then play 10 turns again from a new game with the same seeds.
3. **Results.** Record the run: the turns played, the tool calls per turn, the calls that failed and why, and what Claude Code had to ask or guess. Commit: `docs: record the Claude Code gate`.

## Done when

Claude Code plays 10 turns in a row with only a prompt at the start of each turn. Every action has a `reason`, and the log has no `ERROR` lines.

## Record

- The run, in a new finding, `docs/findings/agent-runs.md*`. Add it to the [findings index](../../findings/README.md).
- Any tool description that misled Claude Code, fixed in its tool. The [tool reference](../../reference/README.md) workflow then commits the new `docs/reference/tools.md` to that PR. The first such PR is the first live run of that commit. Check that the release app's commit lands and that the required checks run again on it.
