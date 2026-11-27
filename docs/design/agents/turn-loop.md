# Turn loop

What an agent does on its turn: resolve the end-turn blockers, act through a small set of general tools, recover from failed actions, and end the turn within fixed limits.

## Steps

The loop starts when the bridge sees the turn-start event for an agent slot. It runs these steps until the turn passes:

1. Read the state and the list of end-turn blockers.
2. Resolve the blockers: a new tech, a pantheon, an era dedication, units that need orders, or a proposed deal.
3. Take the agent's other actions.
4. End the turn.

Plain code handles trivial cases without the LLM, such as fortifying idle units and setting scouts to auto-explore. Quick movement and quick combat stay on during agent turns. [Standing orders](../decision-support/standing-orders.md) let plain code play whole quiet turns without the model.

## Turn signal

`turnSignal(context)` in `src/agents/turn-signal.ts` starts a turn on each `AGENT_TURN` line, from the game's turn event or from the [resync on connect](../core/bridge.md). The core mod prints the line only for agent players, so the bridge plays every player it names, and keeps no list of its own.

The first signal for a player builds its agent: the system prompt, an in-process MCP server whose tools act for that player, and the player's memory folder. Later turns reuse it.

One turn runs at a time for each agent. A signal for a turn that is still running logs `turn_skipped`, and so does a signal on a turn the agent already ended, as [one turn](#one-turn) says.

A game load cancels the running turns and resets the agents, as [game-load.md](game-load.md) says. A turn that ends logs `turn_ended` with the game turn it ended, and one that throws logs `turn_failed` as a warning, so the bridge keeps running and the next signal tries again.

The agents play only in a run mode the [model client](../core/model-client.md) calls. In the Agent SDK and CLI modes, or with no model, the bridge logs `agents_off` once and plays no turns.

## One turn

`playTurn(agent, context, { again, signal })` in `src/agents/loop.ts` plays one turn for one agent:

1. It reads the state for the agent's player. A state it can't read stops the turn before any model call.
2. It skips the turn when the agent already ended that game turn, so a later signal on the same turn, such as one from the resync, never sends a second end turn. It logs `turn_skipped` with the turn and calls no model.

   An `again` signal still plays, because the game cancelled the end and the turn number stays the same. Its turn message tells the model so, because a model can't tell on its own, as [agent-runs.md](../../findings/agent-runs.md#second-run) shows.

   Only an end turn that goes through counts, so a turn that stops plays again on the next signal.
3. It reads the agent's [memory](../memory.md). On the agent's first turn after the bridge starts or a [game loads](game-load.md#cancel-and-reset), it calls `startMemory`, so [stale memory](../memory.md#stale-memory) moves aside. On later turns, it calls `readMemory`. It logs each warning either returns as `memory_warning`.
4. It sends the system prompt, the [turn message](prompt.md#two-calls), and the MCP tools to the model, which `toolDefinitions` in `src/mcp/in-process.ts` lists from the in-process server.
5. It runs the reply's tool calls in order through the MCP server, and sends each result back, marked as an error when the tool failed. A blocked `end_turn` goes back the same way, so the model resolves the blocker and tries again.
6. It calls the model again with the reply and the results added, until an `end_turn` goes through, and keeps that game turn on the agent. The calls after it in the same reply don't run, because it is then another player's turn.

An aborted `signal` cancels the turn after the state read, during the model call, or before the next tool call, so no call from the old game acts in the new one. After a failed tool call, the turn waits for a [silent game](game-load.md#silent-game) before it goes on.

The loop sends each reply back as the SDK's own messages, so a model's reasoning stays in the conversation. Anthropic refuses a tool call conversation with extended thinking that drops it.

A reply with no tool call gets one nudge to act or to call `end_turn`. A second in a row stops the turn. The [turn limits](../../roadmap/phase-2/turn-limits.md) step replaces this with limits per turn.

A failed model call stops the turn with the failure's message. A turn that stops logs `turn_stopped` as a warning, and sends no end turn, so the game waits on the agent. The [forced end turn](../../roadmap/phase-2/forced-end-turn.md) step ends it instead.

The action tools log each action with its `reason`, and the loop logs every tool call at the debug level as `tool_call`. Each model call logs its tokens and cost as `model_call`.

## Tools

There is one tool per kind of decision. For example, `move_unit` moves any unit, and `unit_action(unit, action, target)` covers fortify, found city, build improvement, and pillage.

Cities, research, civics, policies, diplomacy, religion, governors, great people, and the World Congress follow the same pattern. The tool set must let an agent play any strategy it chooses.

For discrete choices, the agent picks from the legal options that `get_choices` returns. For spatial actions, the agent gives a destination, and the game's pathfinding plans multi-turn moves.

Every action tool has a required `reason` field. See [narration-and-messaging.md](narration-and-messaging.md).

## Failure handling

When an action fails, the agent gets the reason and decides again. The loop limits retries per action, actions per turn, and time per turn. When the loop hits a limit, it ends the turn and logs a failure. One stuck turn then cannot stop a game.

## Stopping

Every model call costs money, so you can stop the agent at any moment, and spending limits stop it for you. A run is one start of the bridge.

The bridge stops a run in three ways:

- **Stop key.** Press Ctrl+C in the bridge's console. The bridge aborts the model call in progress, waits for the Lua command in progress, logs `stopped`, and exits. It sends no end turn, so the game waits on the agent's turn. A second Ctrl+C exits at once.
- **Turn count.** `--turns <n>` stops the bridge the same way after the agent ends its n-th turn. Live tests use it to play a fixed number of turns.
- **Spending limits.** `limits` in the [config file](../core/settings.md) caps the tokens of model calls, their cost in dollars, or both, for each turn and each run. A cost limit needs the model's price in the config file.

  A turn that reaches its limit ends like a turn that hits any other limit. A run that reaches its limit stops as the stop key does.

To resume, start the bridge again. [Resync on connect](../core/bridge.md) prints `AGENT_TURN` for the active turn, and the agent reads the state, which already holds the actions it took before the stop.

The limits start blank, so there is no limit until you set one, and the bridge warns when none is set. The smoke test's measured tokens and cost per turn are a guide.

## Decision records

During testing, the agent records each important decision with its reason. It adds the short-term result on the next turn and the long-term result at its next deep strategic review.

The records are noisy, and that is acceptable. You review them over time and turn useful patterns into [knowledge files](../knowledge-files.md).

- **`record_decision`** appends `{ schemaVersion, id, turn, decision, reason }` to the agent's `decisions.jsonl`, in its [memory folder](../memory.md#files-on-disk). `id` counts from 1, and the tool returns it. The decision and the reason are capped at 300 characters each.
- **Next turn.** The turn message lists the records from the agent's last turn before this one that have no `result` yet, each with its id, and asks for each short-term result. When there are none, the [prompt](prompt.md#two-calls) leaves the part out.
- **`record_result`** sets `result` on the record with the id, and rewrites the file. The file holds a few lines per turn, so the rewrite costs little, and each record keeps its result on its own line.

The long-term result at a deep strategic review comes in a later phase.

## Decisions

| Decision | Reason |
| --- | --- |
| One tool per kind of decision | A small set of general tools is easier for the model to use, and it still covers every action |
| Retry, action, and time limits per turn | One stuck turn cannot stop a game |
| The stop key aborts the model call and sends no end turn | Stopping costs nothing more, and the turn resumes from the state when the bridge starts again |
| The run spending limit counts one start of the bridge, not one game | A game outlives restarts, so a total per game needs stored totals. Each call's cost is already in the log |
| Spending limits in tokens, dollars, or both, blank to start | Users pay in dollars, but neither the AI SDK nor the providers' model lists give a price, so a dollar limit needs a price that the user enters. A token limit needs nothing |
| Record decisions and their results during testing | Noisy records still show which patterns belong in knowledge files |
| The model names a record by an id that the bridge gives it | The turn and the text can repeat, and a number costs the fewest tokens |
| The bridge plays every player that `AGENT_TURN` names, with no list of agents in the config | The core mod decides which players are agents, and agent slots save with the game, as [settings.md](../core/settings.md) says. A computer slot agent needs no bridge change |
| The loop sends replies back as the SDK's own messages | The messages keep the model's reasoning, which Anthropic needs back in a tool call conversation with extended thinking |
| The agent keeps the game turn it last ended, and skips a later signal on that turn | The turn signal drives the loop, so it needs no poll of the turn number and no timeout that a long AI turn could trip. A dropped end turn is the [forced end turn](../../roadmap/phase-2/forced-end-turn.md) step's case |
| A reply with no tool call gets one nudge, and a second stops the turn | A model that only writes may still act when asked, and until the turn limits exist, the stop keeps a talking model from spending without end |
