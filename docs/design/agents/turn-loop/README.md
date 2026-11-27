# Turn loop

What an agent does on its turn: resolve the end-turn blockers, act through a small set of general tools, recover from failed actions, and end the turn within fixed limits.

| File | Covers |
| --- | --- |
| [failure-handling.md](failure-handling.md) | The retry, action, and time limits, and the forced end turn at a limit |
| [stopping.md](stopping.md) | The stop key, the turn count, the spending limits, and resuming |
| [decision-records.md](decision-records.md) | The decisions the agent records during testing, and their results |

## Steps

The loop starts when the bridge sees the turn-start event for an agent slot. It runs these steps until the turn passes:

1. Read the state and the list of end-turn blockers.
2. Resolve the blockers: a new tech, a pantheon, an era dedication, units that need orders, or a proposed deal.
3. Take the agent's other actions.
4. End the turn.

The model gives every unit order, including fortify and auto-explore. Plain code gives none on its own. Quick movement and quick combat stay on during agent turns, as [game options](#game-options) says. [Standing orders](../../decision-support/standing-orders.md) let plain code play whole quiet turns without the model.

## Game options

Two game options slow an agent's turn when they're off: `QuickMovement` and `QuickCombat`, the quick movement and quick combat options in the game's Gameplay options. Each unit move or fight then plays its full animation before the next action.

When an agent turn starts, the core mod checks both and prints an `OPTION_OFF` line for each one that's off, before the turn signal, as [lines.md](../../core/mod/lines.md#turn-events) says. The bridge logs it as an `option_off` warning and plays the turn anyway. Nothing turns the options on, because they're the user's settings.

## Turn signal

`turnSignal(context)` in `src/agents/turn-signal.ts` starts a turn on each `AGENT_TURN` line, from the game's turn event or from the [resync on connect](../../core/bridge.md). The core mod prints the line only for agent players, so the bridge plays every player it names, and keeps no list of its own.

The first signal for a player builds its agent: the system prompt, an in-process MCP server whose tools act for that player, and the player's memory folder. Later turns reuse it.

One turn runs at a time for each agent. A signal for a turn that is still running logs `turn_skipped`, and so does a signal on a turn the agent already ended, as [one turn](#one-turn) says.

A game load cancels the running turns and resets the agents, as [game-load.md](../game-load.md) says. A turn that ends logs `turn_ended` with the game turn it ended, and one that throws logs `turn_failed` as a warning, so the bridge keeps running and the next signal tries again.

The agents play only in a run mode the [model client](../../core/model-client.md) calls. In the Agent SDK and CLI modes, or with no model, the bridge logs `agents_off` once and plays no turns.

## One turn

`playTurn(agent, context, { again, signal })` in `src/agents/loop.ts` plays one turn for one agent:

1. It reads the state for the agent's player. A state it can't read stops the turn before any model call.
2. It skips the turn when the agent already ended that game turn, so a later signal on the same turn, such as one from the resync, never sends a second end turn. It logs `turn_skipped` with the turn and calls no model.

   An `again` signal still plays, because the game cancelled the end and the turn number stays the same. Its turn message tells the model so, because a model can't tell on its own, as [agent-runs.md](../../../findings/agent-runs.md#second-run) shows.

   Only an end turn that goes through counts, so a turn that stops plays again on the next signal.
3. It reads the agent's [memory](../../memory.md). On the agent's first turn after the bridge starts or a [game loads](../game-load.md#cancel-and-reset), it calls `startMemory`, so [stale memory](../../memory.md#stale-memory) moves aside. On later turns, it calls `readMemory`. It logs each warning either returns as `memory_warning`.
4. It sends the system prompt, the [turn message](../prompt.md#two-calls), and the MCP tools to the model, which `toolDefinitions` in `src/mcp/in-process.ts` lists from the in-process server.
5. It runs the reply's tool calls in order through the MCP server, and sends each result back, marked as an error when the tool failed. A blocked `end_turn` goes back the same way, so the model resolves the blocker and tries again.
6. It calls the model again with the reply and the results added, until an `end_turn` goes through, and keeps that game turn on the agent. The calls after it in the same reply don't run, because it is then another player's turn.

An aborted `signal` cancels the turn after the state read, during the model call, or before the next tool call, so no call from the old game acts in the new one. After a failed tool call, the turn waits for a [silent game](../game-load.md#silent-game) before it goes on.

The loop sends each reply back as the SDK's own messages, so a model's reasoning stays in the conversation. Anthropic refuses a tool call conversation with extended thinking that drops it.

A reply with no tool call gets a nudge to act or to call `end_turn`. It counts as a failure against the [turn limits](failure-handling.md).

A [turn limit](failure-handling.md) ends the turn with `force`. A failed model call stops the turn with a message that says why. A turn that stops logs `turn_stopped` as a warning, and sends no end turn, so the game waits on the agent.

The action tools log each action with its `reason`, and the loop logs every tool call at the debug level as `tool_call`. Each model call logs its tokens and cost as `model_call`.

A failed call's record holds the text the model got in `failure`, and its message holds the first line, so the log says why, such as a game that didn't answer.

## Tools

There is one tool per kind of decision. For example, `move_unit` moves any unit, and `unit_action(unit, action, target)` covers fortify, found city, build improvement, and pillage.

Cities, research, civics, policies, diplomacy, religion, governors, great people, and the World Congress follow the same pattern. The tool set must let an agent play any strategy it chooses.

For discrete choices, the agent picks from the legal options that `get_choices` returns. For spatial actions, the agent gives a destination, and the game's pathfinding plans multi-turn moves.

Every action tool has a required `reason` field. See [narration-and-messaging.md](../narration-and-messaging.md).

## Decisions

| Decision | Reason |
| --- | --- |
| One tool per kind of decision | A small set of general tools is easier for the model to use, and it still covers every action |
| The bridge plays every player that `AGENT_TURN` names, with no list of agents in the config | The core mod decides which players are agents, and agent slots save with the game, as [settings.md](../../core/settings.md) says. A computer slot agent needs no bridge change |
| The loop sends replies back as the SDK's own messages | The messages keep the model's reasoning, which Anthropic needs back in a tool call conversation with extended thinking |
| The model gives every unit order | A unit built this turn may need another order. A fresh fortify can't be undone until the turn changes, as [unit-orders.md](../../../findings/actions/unit-orders.md#unit-orders) shows. A fortified unit also leaves the `units` blocker list, so the model misses it |
| The agent keeps the game turn it last ended, and skips a later signal on that turn | The turn signal drives the loop, so it needs no poll of the turn number and no timeout that a long AI turn could trip |
