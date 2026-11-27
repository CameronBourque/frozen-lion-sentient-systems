# Agent runs

Status: confirmed. Two runs of the phase 1 Claude Code gate, and two runs of the phase 2 agent loop, played in a running game on Windows.

How a model plays the game through the MCP tools, with a person prompting each turn or with the bridge's agent loop: the setup, what it called each turn, which calls failed and why, and what it had to guess. The second run passed the gate in [phase 1](../roadmap/phase-1/README.md).

## Questions

- Why do most calls of a turn on a ChatGPT plan read nothing from the prompt cache, when each call starts with the same system prompt and turn message? The [smoke test](../roadmap/phase-2/smoke-test.md) measures the cost per turn.
- Does the agent read the state at the start of every turn when no one prompts it? In the second run, it skipped `get_state` on 3 of 11 prompts and called `end_turn` to find the blockers. The [agent loop](../design/agents/turn-loop/README.md#one-turn) reads the state for it.
- Does `GAME_READY` always carry one turn less than the turn that starts after the load, and why? The end turn run saw it on two loads.

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

### Agent loop run

The bridge executable played with no one prompting it, for the [agent loop](../roadmap/phase-2/done.md#agent-loop) step's check. It ran from a folder with no `knowledge` folder, and read its 3 knowledge files from the executable.

The model was `gpt-6.2-sol` on a ChatGPT plan, in the subscription token mode, with the provider's default effort. The game was a saved game on turn 1.

The turn signal started turn 1 when the bridge connected, through the resync. The model founded Rome, wrote its plan, set production and research, moved its warrior, recorded a decision, and ended the turn in 28 s, with 8 model calls. Each action in the log had its reason.

The next `AGENT_TURN` came 0.5 s after each end turn, so the bridge played on until it was stopped. On turn 2 the model recorded the result of turn 1's decision. On turn 5, `end_turn` came back blocked by a unit that needed orders, and the model was called again with the reason.

The first call of a turn sent about 14,000 input tokens. Each later call in the turn sent the same start plus the new calls and results, up to about 18,500. Only 4 of the 24 calls read from the provider's prompt cache, 9,216 tokens each, and none of the calls on turn 1 did.

The run used 10% of a ChatGPT Plus plan's 5-hour limit and 2% of its weekly limit, as the plan's usage page showed after it. Nothing else used the plan in that 5-hour window, and an earlier `npm run ask` check moved neither limit.

At that rate, the 5-hour limit holds about 50 turns like these, and the weekly limit about 250. Later turns hold more state, so they cost more.

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

### End turn run

The bridge executable played turn after turn, for the [end turn](../roadmap/phase-2/done.md#end-turn) step's check. It ran from an empty folder with `logLevel: debug`, on the same model, plan, and effort as the agent loop run, and the same saved game.

It ended turns 1 to 10 in a row with no help, with 41 model calls, 48 tool calls, and 38 actions, each with its reason. No record was a warning or an error.

The game cancelled the end of turns 5 and 7, and sent `AGENT_TURN 0 again` 0.5 s after each. Each time the model gave the warrior new orders and ended the turn again, and only one new turn followed.

One `get_choices` call failed on turn 1, right after the model founded Rome, with city ID 1. Rome's ID was 65536.

The `found_city` result said only that the game took the request, and the turn's state was read before Rome existed, so the model had to guess. Its next call left out the city and went through, and later turns used Rome's ID from the state.

The calls sent about 691,000 input tokens and 2,300 output tokens. 13 of the 41 calls read from the prompt cache, 123,000 tokens in all. The run used 16% of the 5-hour plan limit and 2% of the weekly one. At that rate, the 5-hour limit holds about 60 turns like these.

Two loads during the agent's turn then checked the [game load](../design/agents/game-load.md). In the first, the game stopped answering about a minute before `GAME_READY`, from when the load began. Each tool call waited out the tuner's 10 s timeout and failed, and the model was called again after each failure.

7 model calls, about 150,000 input tokens, went to a game that didn't answer, before the cancel came.

A second load spent 2 more calls, about 43,000 tokens. Both loads used 9% of the 5-hour limit and 1% of the weekly one, with the turns played after them. The cancel itself worked each time: `turn_cancelled` came right after `GAME_READY`, and the turn after the reconnect played normally.

The [silent game](../design/agents/game-load.md#silent-game) wait came from that run.

In the rerun, the agent ended turn 9, and during turn 10 the person loaded the autosave of turn 9. A `set_civic` call timed out, the turn logged `game_silent`, and no model call went out until `GAME_READY` cancelled the turn. The agent then played turn 9 again and ended it.

`GAME_READY` carried one turn less than the state in two loads. One said turn 9 before turn 10 played, and the rerun said turn 8 before turn 9 played. The bridge doesn't use that turn for anything yet.

## Method

1. Start a new game with the smoke test preset and its seeds, and start the bridge with `npm run mcp`.
2. Open Claude Code in a folder outside the repo that holds only the `.mcp.json` and the settings above.
3. Send the turn 1 prompt, then the turn prompt at the start of each turn, until turn 11 starts.
4. Read the transcript for each call and its result, and the bridge log for `Player 0's turn started` lines and `ERROR` lines.

The agent loop run started the bridge executable with `--config` and the saved game loaded, picked the subscription token mode in the picker, and stopped the bridge with Ctrl+C. Its counts come from the bridge log's `model_call`, `action`, and `turn_ended` records.

The end turn run ran the bridge executable from an empty folder with `logLevel: debug`, started before the game, and loaded the saved game.

Each load used the game's own load menu during the agent's turn. Its counts come from the `model_call`, `tool_call`, `action`, `turn`, `turn_ended`, `turn_cancelled`, and `game_silent` records.

## Results

- **First run.** Turns 1 to 10, 53 calls, 40 actions with a reason, no `ERROR` lines, and 2 prompts that weren't the turn prompt. Run on Windows on 2026-11-19.
- **Second run.** Turns 1 to 10, 56 calls, 46 actions with a reason, no `ERROR` lines, and only the turn prompt. The bridge log showed 10 turn starts and one start again, at the end of turn 9. Run on Windows on 2026-11-19.
- **Agent loop run.** Turns 1 to 5 with no prompts, 24 model calls, 19 actions with a reason, 4 turns ended, no warnings or errors, and 10% of the 5-hour plan limit and 2% of the weekly one. Run on Windows on 2026-11-26.
- **End turn run.** Turns 1 to 10 in a row with no help, 41 model calls, 38 actions with a reason, 2 ends that the game cancelled and the agent ended again, no warnings or errors, and 16% of the 5-hour limit and 2% of the weekly one.

  Two loads mid-turn cancelled the turn, and after the silent game wait, no model call went to a game that didn't answer. Run on Windows on 2026-11-26.

Date checked: running game on Windows on 2026-11-26.
