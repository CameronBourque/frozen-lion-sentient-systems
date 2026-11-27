# Phase 2: turn loop steps

The finished steps of [phase 2](../README.md) that play the agent's turns: the loop, the end turn, the limits, and the unit orders it adds. The step table's `#` column sets their order.

## Agent loop

Pull request: feat(core): add the agent loop.

It added the agent loop: `playTurn` in `src/agents/loop.ts` reads the state and the memory, sends the prompt and the MCP tools to the model, and runs its tool calls through an in-process MCP server until `end_turn` goes through.

`turnSignal` in `src/agents/turn-signal.ts` starts a turn on each `AGENT_TURN`, from the game or the resync, and builds each player's agent the first time.

On 2026-11-26, the bridge executable, alone in an empty folder, played turn 1 of a saved game on a ChatGPT plan with no manual help, and logged each action with its reason. It played on to turn 5, because nothing yet stops it after an end turn.

- The turn signal and one turn are in [design/agents/turn-loop/](../../../design/agents/turn-loop/README.md#turn-signal).
- `connectClient`, `toolDefinitions`, and `callTool` are in [design/core/mcp-server.md](../../../design/core/mcp-server.md), and the reply's messages are in [design/core/model-client.md](../../../design/core/model-client.md).
- The live run, its tokens, its plan usage, and the prompt cache question are in [findings/agent-runs.md](../../../findings/agent-runs.md#agent-loop-run).

## End turn

Pull request: feat(core): play turn after turn.

It made the agent loop play turn after turn. Each agent keeps the game turn it last ended and skips a later signal on that turn, and a turn the game starts again tells the model it is still the same turn.

A game load cancels the running turn and resets the agents, and a turn waits while the game doesn't answer, so no model call goes to a game that is loading. `turn_ended` logs the game turn, and a failed tool call logs why it failed.

On 2026-11-26, the bridge executable ended turns 1 to 10 in a row with no manual help, and logged each tool call and each action with its reason. Two cancelled ends played again once each, and a load mid-turn cancelled the turn and replayed the loaded turn.

- The turn change, the `again` case, and the tool call log are in [design/agents/turn-loop/](../../../design/agents/turn-loop/README.md#one-turn), and the turn message's `again` line in [design/agents/prompt.md](../../../design/agents/prompt.md#two-calls).
- The cancel, the reset, and the wait for a silent game are in [design/agents/game-load.md](../../../design/agents/game-load.md), and the stale memory check after a load in [design/memory.md](../../../design/memory.md#stale-memory).
- The run, its tokens, its plan usage, and the load signal's turn are in [findings/agent-runs.md](../../../findings/agent-runs.md#end-turn-run).

## Turn limits

Pull request: feat(core): add turn limits.

It added three limits on each agent turn, set in `limits` in the config file: `retriesPerAction`, `actionsPerTurn`, and `turnMinutes`, with `3`, `250`, and `15` as the defaults.

A turn at a limit stops, and logs `turn_stopped` as a warning that names the limit. A reply with no tool call counts as a failure, in place of the old stop after two such replies.

On 2026-11-27, the bridge executable on a ChatGPT plan, with `actionsPerTurn` set to `1`, took one `move_unit` on turn 1 and logged that the turn reached the actions per turn limit of 1. The game stayed on turn 1, because a stopped turn then sent no end turn. The [forced end turn](#forced-end-turn) step changed that.

- The limits, their defaults, and what each one counts are in [design/agents/turn-loop/failure-handling.md](../../../design/agents/turn-loop/failure-handling.md), and the `limits` field in [design/core/settings.md](../../../design/core/settings.md).

## Forced end turn

Pull request: feat(core): force the end turn at the turn limit.

A turn limit now ends the turn with `force`. The forced end's result lists the blockers and the units it skipped, and the loop logs each one as a warning. A forced end that fails stops the turn as before.

On 2026-11-27, the bridge executable on a ChatGPT plan, with `actionsPerTurn` set to `1`, forced the end of turns 1 and 2 and named each skipped blocker and unit. Turn 3 began with no manual help.

- The forced end and its log are in [design/agents/turn-loop/failure-handling.md](../../../design/agents/turn-loop/failure-handling.md), and the skipped list in [design/core/mod/actions/turn.md](../../../design/core/mod/actions/turn.md).
- What each forced end skipped is in [findings/actions/end-turn.md](../../../findings/actions/end-turn.md#the-end-turn-action).

## Auto-explore

Pull request: feat(core): add auto-explore to unit actions.

The model can now set a unit to auto-explore with `unit_action`, and `wake` stops it with the game's cancel command when the game refuses wake. Plain code gives no unit orders, because a fortify can't be undone on the turn it starts.

On 2026-11-27, a scout set to explore moved at once and left the unit blockers. On the next turn, `wake` returned ok, and the scout needed orders again.

- The explore order and the wake fallback are in [design/core/mod/actions/units.md](../../../design/core/mod/actions/units.md#stances), and the rule that the model gives every unit order is in [design/agents/turn-loop/](../../../design/agents/turn-loop/README.md#decisions).
- How auto-explore behaves is in [findings/actions/unit-orders.md](../../../findings/actions/unit-orders.md#auto-explore).
