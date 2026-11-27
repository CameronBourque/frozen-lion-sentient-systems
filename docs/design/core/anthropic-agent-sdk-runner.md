# Anthropic Agent SDK runner

How Anthropic's Claude agents play through `@anthropic-ai/claude-agent-sdk`, in the **Agent SDK** run mode. It is for that one mode, the only way to play on a Claude plan. The SDK runs its own tool loop, so it replaces the bridge's loop for a turn, as [runners](run-modes.md#runners) says. Part of [run modes](run-modes.md).

## Options

`anthropicAgentSdkRunner(model, query)` in `src/agents/runners/anthropic-agent-sdk-runner.ts` builds the runner with the model and effort from `config.model`, as the Agent SDK mode's `runner` will. A test passes a fake `query()`. The runner calls `query()` with:

- `systemPrompt` set to the system prompt, and a prompt stream that starts with the turn message, as [nudge](#nudge) says,
- `tools: []`, the bridge's MCP server in `mcpServers`, `strictMcpConfig: true`, and `settingSources: []`,
- `cwd` set to the agent's memory folder, which holds no `AGENTS.md` or `CLAUDE.md`. The SDK's built-in `cc-plugin-agents-md` plugin still loads with `settingSources: []`, as [plan-access/anthropic.md](../../findings/plan-access/anthropic.md#question-1) shows,
- `persistSession: false`, so each turn starts fresh and writes no session to disk,
- `permissionMode: "dontAsk"`, so a call no hook allows is denied, and no prompt waits on a user,
- an `env` that holds only the sign-in the user picked, as [sign-in](#sign-in) says,
- the [hooks](#hooks),
- an `abortController` that the turn's signal aborts, at the time limit, a game load, or the stop key,
- `model` and `effort` from the config file. A blank model, or the `provider-default` effort, leaves the SDK's default. The picker offers only the efforts the model takes, so the runner keeps no list of its own.

The SDK's `total_cost_usd` is an estimate at API prices, not what a plan costs, so the runner doesn't use it, as [spend](#spend) says.

## Tools

Each turn serves the agent's MCP server over HTTP on a free loopback port, with `startMcpHttp`, and closes it when the turn ends. The SDK connects to it as an `http` server, as the [tools check](../../findings/plan-access/anthropic.md#question-1) did.

The SDK's in-process `sdk` server type needs version 1 of the MCP SDK, and the bridge uses version 2. `query()` itself loads without version 1. npm still installs it, as a peer of the Agent SDK, but no bridge code loads it.

## Hooks

The hooks are adapters. They play each call through the `beforeCall` and `afterCall` steps that every [runner](../agents/turn-loop/README.md#runners) shares, on a `TurnRun` from `startRun`, so the logs and the limits match the bridge's own loop:

- **`PreToolUse`** calls `beforeCall`, which ends the run after an abort, and denies the call. Otherwise it allows each of the bridge's tools and denies any other.
- **`PostToolUse`** calls `afterCall` with a success.
- **`PostToolUseFailure`** calls `afterCall` with the failure's text, so a failed action counts against the retries limit and the run waits for a silent game.

A hook ends the run with `continue: false`. The runner reports the end, and `playTurn` ends the turn with force at a limit, as [runners](../agents/turn-loop/README.md#runners) says. An SDK error stops the turn.

## Nudge

The prompt is a stream that stays open for the turn, so the session goes on after each reply. A result message means a reply with no tool call. It counts as a failure through `countNoToolCall` in `shared.ts`, as in the model client runner, and the runner sends the same `NUDGE` into the session.

Past the retries per action limit, the turn ends with force.

## Spend

The runner counts the spend from the SDK's messages, through `spendCall` in `shared.ts`, so the turn and run spending limits work as in the model client runner:

- **Each assistant message** is one model call, counted once by its message id, since the SDK may send one call as several messages. Its input counts as it comes, so a long round stops at a limit.

  Anthropic's `input_tokens` leaves out the cached input, so the runner adds the cache read and write tokens, as the bridge's `Usage` counts them.
- **Each result message** gives the session's output tokens so far, since an assistant message's output is a placeholder. The round's output is what the total added. The round logs as one `model_call` line.

A turn can go past its token limit by one round's output, which only comes with the result.

The price comes from the config file. On a Claude plan it stays unset, as with a subscription token.

## Sign-in

The SDK runs the Claude Code binary, which signs in with `ANTHROPIC_API_KEY` when it is set, and with the user's claude.ai login when it isn't. The key wins, so a user with both would play on the key without knowing it.

When the Anthropic key in `providers` and the claude.ai login are both ready, the picker shows a **Sign-in** menu with **Claude plan** and **API key**, starting on **Claude plan**.

With only one ready, the menu is skipped and that one is used. With neither, the picker warns and shows the **Run mode** menu again.

The runner passes the SDK an `env` built from the bridge's own environment:

- **Claude plan.** `ANTHROPIC_API_KEY` is removed, so the binary uses the login.
- **API key.** `ANTHROPIC_API_KEY` is set to the key from `providers`. The price comes from the config file, as in the API key mode.

Each start asks again, as the **Run mode** menu does.

## Flag

`CLAUDE_AGENT_SDK_ENABLED` in `src/model/providers/anthropic.ts` is `false`. While it is, Anthropic's `modes` has no agent SDK entry, so the mode reads `(not available yet)`.

Anthropic's terms bar a third-party app from offering claude.ai login without approval. The constant becomes `true` once Anthropic approves.

## Decisions

| Decision | Reason |
| --- | --- |
| `cwd` is the agent's memory folder | The SDK's `cc-plugin-agents-md` plugin loads even with `settingSources: []`. A folder the bridge owns holds no `AGENTS.md`, wherever the user starts the bridge |
| A **Sign-in** menu when both the key and the login are ready | The binary picks the key over the login on its own, so the user would pay API prices with no sign of it. The menu makes it the user's choice |
| The tools reach the SDK over HTTP, not as an in-process server | The in-process server needs MCP SDK version 1. HTTP uses the bridge's own server, which the tools check proved |
| A new HTTP server for each turn | No port stays open between turns, and a turn needs no cleanup when the bridge stops |
| A reply with no tool call gets the nudge in the same session | It keeps the turn's context, as the model client runner does. A new `query()` would start a fresh context and lose the turn so far |
| Each round logs as one model call | The output only comes with the result. A line for each call would log zero output tokens |
| The runner builds the SDK's `env` from the pick | Removing the key is the one way to make the binary use the login. Setting it from `providers` means the config file's key wins, as in the API key mode |
