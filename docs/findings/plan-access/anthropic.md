# Anthropic plan access

Status: question 1 confirmed by a call on 2026-11-27. The rest was read from Anthropic's docs on 2026-11-22, with no call tested.

What Anthropic's terms and the Claude Agent SDK allow for a user's Claude plan. Part of [plan access](README.md).

## Questions

1. In the Claude Agent SDK, does `tools: []` with only the bridge's MCP server remove every built-in tool?
2. How does a Claude plan usage limit show in the Agent SDK's result message?

## What we know now

- **Terms.** Without Anthropic's approval, a third-party product may not offer claude.ai login or plan rate limits. This includes agents built on the Claude Agent SDK. Source: [agent-sdk/overview](https://code.claude.com/docs/en/agent-sdk/overview).
- **Personal use.** The legal page allows a user to sign in to the unmodified Claude Code binary with their own plan. It bars routing requests through plan credentials on behalf of other users. Source: [legal-and-compliance](https://code.claude.com/docs/en/legal-and-compliance).
- **Agent SDK options.** `@anthropic-ai/claude-agent-sdk` takes the following options. Source: [agent-sdk/typescript](https://code.claude.com/docs/en/agent-sdk/typescript).
  - `systemPrompt` as a string, which replaces the default prompt,
  - `tools` to choose the built-in tools, `mcpServers` with `strictMcpConfig`, and `settingSources: []`, which loads no user or project settings,
  - `abortController`, `model`, `effort`, and `supportedModels()`,
  - a new session for each `query()` with no `resume`.
- **Tool calls.** `PreToolUse` and `PostToolUse` hooks see each call, and `PreToolUse` can deny one. Source: [agent-sdk/hooks](https://code.claude.com/docs/en/agent-sdk/hooks).
- **Usage.** Each assistant message has `input_tokens`, `cache_read_input_tokens`, and `cache_creation_input_tokens`. Its `output_tokens` is a placeholder, so output comes from the result message. `total_cost_usd` is an estimate at API prices. Source: [agent-sdk/cost-tracking](https://code.claude.com/docs/en/agent-sdk/cost-tracking).
- **Install.** The package ships the Claude Code binary, and needs Node 18.14 or later.

## Method

1. To answer question 1, run one `query()` with `tools: []`, `settingSources: []`, and only the bridge's MCP server. Then check that the init message lists no built-in tool.
2. To answer question 2, run `query()` on a plan at its limit and log the result message.

## Results

### Question 1

Yes. Checked on 2026-11-27 with `@anthropic-ai/claude-agent-sdk` 0.3.332, which runs Claude Code 2.1.332.

The `query()` had `tools: []`, `settingSources: []`, `strictMcpConfig: true`, and the bridge's MCP server over HTTP. It ran from the repo root with `ANTHROPIC_API_KEY` set, and stopped after the init message, before any model call.

- **Tools.** The init message listed the bridge's 48 tools, each as `mcp__sentient-systems__<name>`, and no built-in tool.
- **Login.** `apiKeySource` was `ANTHROPIC_API_KEY`, so no plan login was used.
- **MCP server.** `sentient-systems` was `connected`, with `source` `dynamic`.
- **Model.** With no `model` set, it was `claude-opus-5-5`.
- **Skills and plugins.** It still listed the SDK's bundled skills and slash commands, and four built-in plugins, one of them `cc-plugin-agents-md`. With no built-in tool, the model has no tool that runs a skill.

  The init message doesn't say whether `cc-plugin-agents-md` loaded the repo's `AGENTS.md`. The [parity check](../../design/core/run-modes.md#parity-check) bars that, so the [Anthropic Agent SDK runner](../../design/core/anthropic-agent-sdk-runner.md) sets `cwd` to a folder with no `AGENTS.md`.

### Question 2

Not checked yet.

Date checked: 2026-11-27.
