# Agent runs

Status: confirmed. Two runs of the phase 1 Claude Code gate, played in a running game on Windows.

How a model plays the game through the MCP tools, with a person prompting each turn: the setup, what it called each turn, which calls failed and why, and what it had to guess. The second run passed the gate in [phase 1](../roadmap/phase-1/README.md).

## Questions

- Does the agent read the state at the start of every turn when no one prompts it? In the second run, it skipped `get_state` on 3 of 11 prompts and called `end_turn` to find the blockers. The [agent loop](../roadmap/phase-2/agent-loop.md) reads the state for it.

## What we know now

### Setup

Both runs used the smoke test preset in [design/testing.md](../design/testing.md#presets), with map seed `1796629901` and game random seed `1796629900`, and a new game each time. The model was `claude-opus-5-5` in Claude Code, and the bridge ran with `npm run mcp`.

Claude Code ran in a folder outside the repo, so it couldn't read the code or the docs. The folder held only a `.mcp.json` that names the server at `http://127.0.0.1:4320/mcp`, and a `.claude/settings.local.json` that allows the game's tools and denies the file, shell, web, and agent tools.

The prompt on turn 1:

```text
You’re playing Civilization VI as player 0, in a single-player game against one AI on a small Pangaea map. You play only through the sentient-systems tools. Each action takes a reason: one sentence on why you take it. Play to win. I’ll tell you when each turn starts.

It’s your turn. Read the state, play the turn, and call end_turn.
```

The prompt at the start of every later turn:

```text
It’s your turn. Read the state, play the turn, and call end_turn.
```

### First run

It played turns 1 to 10, with 53 calls to the game's tools. All 40 actions had a reason, and the bridge log had no `ERROR` lines. It didn't pass the gate, because it needed two prompts that weren't the turn prompt:

- **Turn 2.** The person sent "End the turn" instead of the turn prompt, by mistake.
- **Turn 5.** The person clicked Next Turn in the game.

| Turn | Calls | What failed, and why |
| --- | --- | --- |
| 1 | 10 | A move right after founding the capital had no route. The game sometimes returns no path for a moment after a city is founded |
| 2 to 4 | 10 | A settler at size 1, which the game refuses |
| 5 | 13 | `end_turn` refused 3 times as a turn already ended. A queued move stopped short, the game cancelled the end of the turn, and the core mod still held the old request |
| 6 to 10 | 20 | Blockers that `end_turn` named, as it should |

On turn 4 it sent its warrior to unrevealed coast. The move returned ok, and the warrior then stood still with the move queued, and nothing named it as needing orders. It read a bigger y as south, and a tribal village gave a reward that the state didn't show.

### Second run

It played turns 1 to 10, with 56 calls to the game's tools. All 46 actions had a reason, and the bridge log had no `ERROR` lines. The person sent only the turn prompt. It passed the gate.

| Turn | Calls | What failed, and why |
| --- | --- | --- |
| 1 to 6 | 27 | A settler at size 1 |
| 7 | 8 | `end_turn` named the builder from the tribal village. The events said "A tribal village at (15, 7) gave grant builder." |
| 8 | 7 | `end_turn` named the research choice and two units |
| 9 | 10 | A builder with no moves left, and units that `end_turn` named |
| 10 | 4 | `end_turn` named the civic choice |

At the end of turn 9, a queued move stopped at a tile the scout couldn't enter. The game cancelled the end of the turn, and the core mod cancelled the scout's move, so `end_turn` named the scout. The bridge logged that the turn started again.

The person then sent the turn prompt, and Claude Code took it as turn 10. Its first call, the builder's quarry, failed with no moves left, and it guessed the builder was still walking. It counted every later turn one too high, and called the last turn 11.

`end_turn` had returned "The game took the request." before the game cancelled the end, and the state had no turn number.

### What the runs changed

Each problem got its own pull request before the second run, except the turn number, which came after it:

| Problem | Pull request |
| --- | --- |
| `end_turn` after a cancelled end | `fix(core): allow end turn after the game cancels it` |
| No route right after founding a city | `fix(core): say when to retry a move with no route` |
| A queued move into unrevealed tiles that can't finish | `fix(core): cancel moves whose destination can't be reached` |
| A replacement character in Kamāl ud-Dīn Behzād | `fix(core): keep the characters of localized text` |
| No tribal village reward in the events | `feat(core): add tribal village rewards to the events` |
| North and south swapped in the reasons | `fix(core): say which way the map's coordinates run` |
| The turn count off by one after a cancelled end | `feat(core): add the current turn to the state` |

## Method

1. Start a new game with the smoke test preset and its seeds, and start the bridge with `npm run mcp`.
2. Open Claude Code in a folder outside the repo that holds only the `.mcp.json` and the settings above.
3. Send the turn 1 prompt, then the turn prompt at the start of each turn, until turn 11 starts.
4. Read the transcript for each call and its result, and the bridge log for `Player 0's turn started` lines and `ERROR` lines.

## Results

- **First run.** Turns 1 to 10, 53 calls, 40 actions with a reason, no `ERROR` lines, and 2 prompts that weren't the turn prompt. Run on Windows on 2026-11-19.
- **Second run.** Turns 1 to 10, 56 calls, 46 actions with a reason, no `ERROR` lines, and only the turn prompt. The bridge log showed 10 turn starts and one start again, at the end of turn 9. Run on Windows on 2026-11-19.

Date checked: running game on Windows on 2026-11-19.
