# Claude runner

How Claude agents play through `@anthropic-ai/claude-agent-sdk`, in the **Agent SDK** run mode. The SDK runs its own tool loop, so it replaces the bridge's loop for a turn, as [runners](run-modes.md#runners) says. Part of [run modes](run-modes.md).

## Options

The runner calls `query()` with:

- `systemPrompt` set to the system prompt, and the turn message as the prompt,
- `tools: []`, the bridge's MCP server in `mcpServers`, `strictMcpConfig: true`, and `settingSources: []`,
- `cwd` set to the agent's memory folder, which holds no `AGENTS.md` or `CLAUDE.md`. The SDK's built-in `cc-plugin-agents-md` plugin still loads with `settingSources: []`, as [plan-access/anthropic.md](../../findings/plan-access/anthropic.md#question-1) shows,
- an `env` that holds only the sign-in the user picked, as [sign-in](#sign-in) says,
- `PreToolUse` and `PostToolUse` hooks that log each call and count it against the turn limits, and end the run after `end_turn`,
- an `abortController` that the stop key aborts,
- `model` and `effort` from the config file.

The SDK's `total_cost_usd` is an estimate at API prices, not what a plan costs, so the price stays unset, as with a subscription token.

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
| The runner builds the SDK's `env` from the pick | Removing the key is the one way to make the binary use the login. Setting it from `providers` means the config file's key wins, as in the API key mode |
