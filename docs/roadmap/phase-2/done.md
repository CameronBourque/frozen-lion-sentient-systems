# Phase 2: done steps

The finished steps of [phase 2](README.md). The step table's `#` column sets their order.

## Model client

Pull request: feat(core): add the model client.

It added the model client, which calls Anthropic, OpenAI, or Google through the Vercel AI SDK, and a picker that asks for the provider, the model, and the effort when the bridge starts.

Each model's price, tool support, and effort levels come from OpenRouter's public model list. Each call logs its tokens and cost, and retries a rate limit or a server error. `npm run ask` returned a tool call from each provider, and a refused key named its config field.

- The client, the providers, the model list, the failures, and `npm run ask` are in [design/core/model-client.md](../../design/core/model-client.md). The picker and the prices are in [design/core/picker.md](../../design/core/picker.md).
- The `providers` and `model` fields, and the environment variables that fill a blank key, are in [design/core/settings.md](../../design/core/settings.md).

## Personality and sweat level

Pull request: feat(core): add the neutral personality and the balanced sweat level.

It added the neutral personality, the balanced sweat level, and the rules of play as knowledge files in `packages/core/bridge/knowledge/`, which the executable carries as Node SEA assets.

It also added `systemPrompt` and `turnMessage` in `src/agents/prompt.ts`, which build the prompt from them and the state.

The executable, copied alone to an empty folder, read the 3 files. A test builds the prompt from the shipped files and a fixed state. The executable builds its first real prompt in the [agent loop](#agent-loop) step.

- Where the files live, their format, and the neutral personality are in [design/knowledge-files.md](../../design/knowledge-files.md#file-layout).
- How the prompt is built, and why the state goes in once per turn, are in [design/agents/prompt.md](../../design/agents/prompt.md).
- How the executable carries the files is in [design/distribution.md](../../design/distribution.md), with the asset facts in [findings/build-tooling.md](../../findings/build-tooling.md).
- **Random** resolving to a personality when the game starts is in [design/agents/slot-type.md](../../design/agents/slot-type.md).

## Memory and decision records

Pull request: feat(core): add plan and journal memory.

It added each agent's memory files in `memory/player-<ID>/`, next to the config file: `plan.md`, `journal.md`, and `decisions.jsonl`. It also added the four tools that change them, `update_plan`, `add_journal_entry`, `record_decision`, and `record_result`, and their parts in the turn message.

A file the store can't read moves aside with a warning. Until checkpoint IDs exist, `startMemory` moves stale memory aside on turn 1 or an earlier turn than the memory holds.

A test runs two fake turns through the tools and checks all three files. The agent loop calls `startMemory` in the [agent loop](#agent-loop) step.

- The files, their formats, unreadable files, and stale memory are in [design/memory.md](../../design/memory.md#files-on-disk).
- The decision records and their results are in [design/agents/turn-loop/decision-records.md](../../design/agents/turn-loop/decision-records.md).
- The memory tools and the `memory` source are in [design/core/mcp-server.md](../../design/core/mcp-server.md).
- The plan, journal, and decision parts of the turn message are in [design/agents/prompt.md](../../design/agents/prompt.md#two-calls).
- The `journalEntries` cap is in [design/core/settings.md](../../design/core/settings.md).

## Run mode menu

Pull request: feat(core): add the run mode menu.

It moved each provider into its own file in `src/model/providers/`, listed in `PROVIDERS`, and added a **Run mode** menu before the provider menu. The menu lists the four run modes and **Quit**, starting on **API key**, and only **API key** plays.

A mode that no provider has reads `(not available yet)`. **What now?** gained **Pick another run mode**, and the `model_chosen` log line names the run mode. The bridge doesn't save the run mode.

`npm run ask` passed every case in a terminal on 2026-11-23.

- The provider files and the menu's rules are in [design/core/run-modes.md](../../design/core/run-modes.md#providers).
- The menus, in order, are in [design/core/picker.md](../../design/core/picker.md#menus).

## ChatGPT plan

Pull request: feat(core): run agents on a ChatGPT plan.

It turned on the **Subscription token** run mode for OpenAI. Picking **Continue with ChatGPT** signs in through the browser, and the bridge saves the tokens in `auth/openai.json`, refreshes them before they expire, and calls OpenAI's API with them.

Each plan error code is its own failure kind, and a plan model has no price, so its calls log no cost. The repo is now under the Apache License 2.0.

On 2026-11-25, `npm run ask` signed in on a ChatGPT Plus plan, listed the plan's models with no prices, and printed the tool call. Its `model_call` record had 85 input and 20 output tokens and no cost. Once the access token expired, the next run refreshed it with no browser.

In the API key mode it printed the tool call for Anthropic. OpenAI and Google wait for an API key to check.

- The sign-in, the tokens, the refresh, and the calls are in [design/core/subscription-token.md](../../design/core/subscription-token.md).
- The credential, `subscriptionMode`, and the picker's sign-in row are in [design/core/run-modes.md](../../design/core/run-modes.md#providers).
- The failure kinds are in [design/core/model-client.md](../../design/core/model-client.md#failures), and `auth/` is in [design/core/settings.md](../../design/core/settings.md).
- The live check's results are in [findings/plan-access/openai.md](../../findings/plan-access/openai.md#results), and the license and why are in [design/distribution.md](../../design/distribution.md).

## xAI provider

Pull request: feat(core): add xAI as a provider.

It added xAI as a fourth provider in the **API key** mode, through `@ai-sdk/xai`, with `XAI_API_KEY` for a blank key. Its model list reads `/v1/language-models`, which leaves out xAI's image and video models. xAI's plan sign-in waits on xAI's answer in [findings/plan-access/xai.md](../../findings/plan-access/xai.md).

The saved model now keeps the run mode it was picked in, as `model.mode`. After a failed list, **Use** runs it in that mode, so a model picked on a ChatGPT plan no longer runs on a refused API key. The picker's design moved to its own file.

On 2026-11-25, `npm run ask` named a refused OpenAI key's config field, and **Use** ran the saved plan model on the plan. The xAI list and a Grok call wait for an xAI API key to check.

- The xAI lister is in [design/core/model-client.md](../../design/core/model-client.md#model-lists), and its key is in [design/core/settings.md](../../design/core/settings.md).
- The saved run mode and **Use** are in [design/core/run-modes.md](../../design/core/run-modes.md#picker), and the menus are in [design/core/picker.md](../../design/core/picker.md#menus).

## Agent loop

Pull request: feat(core): add the agent loop.

It added the agent loop: `playTurn` in `src/agents/loop.ts` reads the state and the memory, sends the prompt and the MCP tools to the model, and runs its tool calls through an in-process MCP server until `end_turn` goes through.

`turnSignal` in `src/agents/turn-signal.ts` starts a turn on each `AGENT_TURN`, from the game or the resync, and builds each player's agent the first time.

On 2026-11-26, the bridge executable, alone in an empty folder, played turn 1 of a saved game on a ChatGPT plan with no manual help, and logged each action with its reason. It played on to turn 5, because nothing yet stops it after an end turn.

- The turn signal and one turn are in [design/agents/turn-loop/](../../design/agents/turn-loop/README.md#turn-signal).
- `connectClient`, `toolDefinitions`, and `callTool` are in [design/core/mcp-server.md](../../design/core/mcp-server.md), and the reply's messages are in [design/core/model-client.md](../../design/core/model-client.md).
- The live run, its tokens, its plan usage, and the prompt cache question are in [findings/agent-runs.md](../../findings/agent-runs.md#agent-loop-run).

## End turn

Pull request: feat(core): play turn after turn.

It made the agent loop play turn after turn. Each agent keeps the game turn it last ended and skips a later signal on that turn, and a turn the game starts again tells the model it is still the same turn.

A game load cancels the running turn and resets the agents, and a turn waits while the game doesn't answer, so no model call goes to a game that is loading. `turn_ended` logs the game turn, and a failed tool call logs why it failed.

On 2026-11-26, the bridge executable ended turns 1 to 10 in a row with no manual help, and logged each tool call and each action with its reason. Two cancelled ends played again once each, and a load mid-turn cancelled the turn and replayed the loaded turn.

- The turn change, the `again` case, and the tool call log are in [design/agents/turn-loop/](../../design/agents/turn-loop/README.md#one-turn), and the turn message's `again` line in [design/agents/prompt.md](../../design/agents/prompt.md#two-calls).
- The cancel, the reset, and the wait for a silent game are in [design/agents/game-load.md](../../design/agents/game-load.md), and the stale memory check after a load in [design/memory.md](../../design/memory.md#stale-memory).
- The run, its tokens, its plan usage, and the load signal's turn are in [findings/agent-runs.md](../../findings/agent-runs.md#end-turn-run).

## Turn limits

Pull request: feat(core): add turn limits.

It added three limits on each agent turn, set in `limits` in the config file: `retriesPerAction`, `actionsPerTurn`, and `turnMinutes`, with `3`, `250`, and `15` as the defaults.

A turn at a limit stops, and logs `turn_stopped` as a warning that names the limit. A reply with no tool call counts as a failure, in place of the old stop after two such replies.

On 2026-11-27, the bridge executable on a ChatGPT plan, with `actionsPerTurn` set to `1`, took one `move_unit` on turn 1 and logged that the turn reached the actions per turn limit of 1. The game stayed on turn 1, because a stopped turn then sent no end turn. The [forced end turn](#forced-end-turn) step changed that.

- The limits, their defaults, and what each one counts are in [design/agents/turn-loop/failure-handling.md](../../design/agents/turn-loop/failure-handling.md), and the `limits` field in [design/core/settings.md](../../design/core/settings.md).

## Forced end turn

Pull request: feat(core): force the end turn at the turn limit.

A turn limit now ends the turn with `force`. The forced end's result lists the blockers and the units it skipped, and the loop logs each one as a warning. A forced end that fails stops the turn as before.

On 2026-11-27, the bridge executable on a ChatGPT plan, with `actionsPerTurn` set to `1`, forced the end of turns 1 and 2 and named each skipped blocker and unit. Turn 3 began with no manual help.

- The forced end and its log are in [design/agents/turn-loop/failure-handling.md](../../design/agents/turn-loop/failure-handling.md), and the skipped list in [design/core/mod/actions/turn.md](../../design/core/mod/actions/turn.md).
- What each forced end skipped is in [findings/actions/end-turn.md](../../findings/actions/end-turn.md#the-end-turn-action).
