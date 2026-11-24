# Plan access

Status: unconfirmed. Read from each provider's docs on 2026-11-22, with no sign-in or call tested yet.

Which providers let the bridge use a user's paid plan, such as ChatGPT Plus or Claude Max, in place of an API key, and through what: a token for the provider's API, an agent SDK, or a CLI. [design/core/run-modes.md](../design/core/run-modes.md) uses these facts.

## Questions

1. Does a Responses API reply on a ChatGPT plan token report input, cached, and output tokens?
2. Does the AI SDK's OpenAI provider send a plan token call in the shape the plan requires, with `store: false`, streaming, and none of the rejected fields?
3. In the Claude Agent SDK, does `tools: []` with only the bridge's MCP server remove every built-in tool?
4. How does a Claude plan usage limit show in the Agent SDK's result message?
5. Which URLs and parameters do the ChatGPT sign-in, the first-time registration, and the token refresh use?
6. Which ChatGPT plans besides Plus and Pro can use plan usage?
7. Which fields does a `/v1/models` entry have on a ChatGPT plan token?
8. Does a ChatGPT plan call accept `include: ["reasoning.encrypted_content"]`, which the AI SDK adds to a reasoning model's call with `store: false`?

## What we know now

### OpenAI

- **ChatGPT plan usage.** An open-source app that runs on the user's computer may send requests on the user's ChatGPT plan. The overview says it is "for open-source and locally hosted apps". Paid or hosted apps use an interest form instead. Source: [token-sharing-open-source](https://developers.openai.com/siwc/token-sharing-open-source).
- **Registration.** None ahead of time. The first sign-in passes `client_id=dynamic_agent_client`, `ext_agent_host_id`, and `agent_name_hint`, and the callback returns an issued `client_id` to save and reuse. No client secret or partner key. Source: [sign-in](https://developers.openai.com/siwc/token-sharing-open-source/sign-in).
- **What counts as open source.** The docs don't define it or name a license.
- **Sign-in.** Browser OAuth with PKCE `S256`. The redirect is an HTTP loopback on `127.0.0.1`, never `localhost`, and only the port may change. No device code flow.
- **Scopes.** `openid profile email offline_access resource.invoke chatgpt.tokens.use.direct`. Plan usage needs `chatgpt.tokens.use.direct` in the granted scopes.
- **Tokens.** The access token lasts 1 hour. The refresh token lasts 30 days, and each refresh returns a new one with a new 30 days. Refreshes must not run at the same time. `invalid_grant`, `refresh_token_reused`, and `refresh_token_expired` mean sign in again. Source: [token-reference](https://developers.openai.com/siwc/token-sharing-open-source/token-reference).
- **Calls.** `POST https://api.openai.com/v1/responses` with the token as `Authorization: Bearer`. Every request sets `store: false` and `stream: true`. A reply counts only after `response.completed`. Source: [models-and-inference](https://developers.openai.com/siwc/token-sharing-open-source/models-and-inference).
- **Rejected fields.** These include `max_output_tokens`, `temperature`, `top_p`, `prompt_cache_retention`, `metadata`, `user`, and `previous_response_id`.

  A `system` role message is rejected, so the system prompt goes in `instructions`. Source: [preview-limitations](https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations).
- **Tools.** Function tools work. Hosted MCP, file search, and Code Interpreter don't.
- **Models.** `GET https://api.openai.com/v1/models` with the token, keeping each entry whose `visibility` is `list`.
- **Plans and limits.** Plus and Pro. A Plus plan's five-hour limit is shared by every app that uses the plan. Pro has no five-hour limit. Source: [profiles-and-sessions](https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions).
- **Errors.** `subscription_sharing_usage_limit_exceeded` (429), `subscription_sharing_usage_unavailable` (503), `subscription_sharing_user_not_eligible` (403), and `subscription_sharing_unsupported_capability` (400).

  A limit can arrive mid-stream as `response.failed`. The docs say not to guess a reset time from the code. Source: [errors-and-recovery](https://developers.openai.com/siwc/token-sharing-open-source/errors-and-recovery).
- **Wording.** The sign-in action reads "Continue with ChatGPT". The first sign-in shows "You're using your ChatGPT plan", and a usage limit links to `https://chatgpt.com/settings/usage`. Source: [ui-ux-guidelines](https://developers.openai.com/siwc/ui-ux-guidelines).
- **Codex SDK.** `@openai/codex-sdk` spawns the `codex` CLI and streams its events. Its docs show no way to abort a run. Source: [codex-sdk](https://learn.chatgpt.com/docs/codex-sdk).

### Anthropic

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

### Google

- **Gemini CLI.** Since 2026-06-18, Gemini CLI serves only Gemini Code Assist Standard and Enterprise licenses. Free personal use and Google AI Pro and Ultra moved to Antigravity CLI. Source: [gemini-cli README](https://github.com/google-gemini/gemini-cli).
- **Terms.** Using the services behind Gemini CLI from third-party software violates Google's terms. Source: [tos-privacy](https://geminicli.com/docs/resources/tos-privacy/).
- **Antigravity SDK.** Python only. Source: [antigravity-sdk](https://antigravity.google/product/antigravity-sdk).
- **Antigravity CLI.** The FAQ says using third-party software, tools, or services to access Antigravity violates the terms, and can lead to suspension. It points third-party coding agents to a Vertex or AI Studio API key. Source: [faq](https://antigravity.google/docs/faq).

  Headless mode (`agy -p`) is for the user's own scripts and CI. Forum replies disagree on whether another app may launch it, and none covers an app that replaces its prompt and tools for other users, as the bridge would. Source: [forum thread](https://discuss.ai.google.dev/t/is-it-allowed-for-an-open-source-tool-to-call-the-official-agy-cli-in-headless-mode/183429).

## Method

1. To answer questions 1 and 2, sign in with a ChatGPT Plus plan, run `npm run ask`, and check the `model_call` record for nonzero input and output tokens.
2. To answer question 3, run one `query()` with `tools: []`, `settingSources: []`, and only the bridge's MCP server. Then check that the init message lists no built-in tool.
3. To answer question 4, run `query()` on a plan at its limit and log the result message.
4. To answer questions 5 to 8, read the OpenAI pages linked in [OpenAI](#openai). If the pages don't answer question 8, run step 1 and check that the call has no error that names `include`.

## Results

None yet.

Date checked: 2026-11-22.
