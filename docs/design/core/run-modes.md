# Run modes

How agents reach a model: with an API key, a subscription token, a provider's agent SDK, or a provider's CLI. The picker asks for the run mode first, and each mode lists only the providers that support it. Part of the [bridge](bridge.md).

## Modes

The four run modes differ in who runs the tool loop and how the user signs in.

| Run mode | `model.mode` | Who runs the tool loop | Sign-in | Providers |
| --- | --- | --- | --- | --- |
| **API key** | `api-key` | The bridge's [agent loop](../agents/turn-loop.md), through the [model client](model-client.md) | An API key in `providers` in the [config file](settings.md) | Anthropic, OpenAI, Google |
| **Subscription token** | `subscription` | The bridge's agent loop, through the model client | The provider's browser sign-in for the user's plan | OpenAI, on a ChatGPT plan |
| **Agent SDK** | `agent-sdk` | The provider's agent SDK | The provider's own login for the user's plan | Anthropic, behind a flag |
| **CLI** | `cli` | The provider's CLI, started once per turn | The CLI's own login | None |

For a provider with more than one plan mode, the bridge offers the first that works, in this order:

1. Subscription token, because the bridge keeps its own loop, so every feature works the same as with an API key.
2. Agent SDK, when it passes the [parity check](#parity-check).
3. CLI, when the provider has no agent SDK that passes, and its CLI passes the same check.

[findings/plan-access.md](../../findings/plan-access.md) has what each provider allows. Google offers no plan mode, so it is API key only.

## Mode table

`RUN_MODES` in `src/model/run-modes.ts` lists each run mode with its providers. Each provider in a mode has a status:

- `ready`, which the picker offers,
- `flagged`, which waits on a constant in the code and counts as not ready while that constant is false.

A provider missing from a mode isn't offered in it. To add a provider to a mode, add its row and its adapter: a sign-in for a subscription token, or a runner for an agent SDK or a CLI.

## Picker

The picker in [model-client.md](model-client.md#picker) starts with a **Run mode** menu that lists all four modes. A mode with no ready provider reads `(not available yet)`. Choosing it says so and shows the menu again.

The menus after it depend on the mode:

- **API key.** Provider, model, and effort, as today.
- **Subscription token.** Provider, then a browser sign-in when there is no valid token, then model and effort from the provider's own list.
- **Agent SDK.** Provider, a login check, then model and effort from the SDK's list.
- **CLI.** Provider, a check that the CLI is installed and logged in, then model and effort.

A provider menu with one provider is skipped, as today. Without a terminal, the bridge uses the saved mode and model, and warns when that mode can't play, such as when the token has expired.

`model.mode` defaults to `api-key`, so a config file from before run modes keeps working.

## Subscription token

The bridge's loop and the model client stay the same. The provider model gets a token in place of an API key, and the model client streams the call. OpenAI's ChatGPT plan usage is the one provider.

- **Sign-in.** `signIn` in `src/model/sign-in/openai.ts` opens the browser to OpenAI's OAuth page with PKCE, and listens on `127.0.0.1` on a free port for the callback. The menu row reads "Continue with ChatGPT".

  The first sign-in registers the bridge with `dynamic_agent_client`, a random `ext_agent_host_id`, and `agent_name_hint` set to `Sentient Systems`. It saves the issued `client_id`, which every later sign-in and refresh uses.
- **Tokens.** `auth/openai.json` in the config file's folder holds the client ID, the host ID, and the tokens. The config file never does, because users may share it, and the refresh token changes on every refresh.
- **Refresh.** The bridge refreshes the access token a minute before its hour ends, one refresh at a time. A refused refresh clears the tokens, and the picker asks to sign in again on the next start.
- **Calls.** Each call goes to the Responses API with `store: false`, streamed, and with none of the fields the plan rejects. The model list comes from `/v1/models` with the token, keeping the entries whose `visibility` is `list`.
- **First use.** After the first sign-in, the bridge logs "You're using your ChatGPT plan", with the usage page.
- **Failures.** A usage limit is a failure marked `limit`. The agent loop logs it with `https://chatgpt.com/settings/usage`, and stops the run as a run spending limit does. An account that isn't eligible is an `auth` failure that names the plan.
- **Price.** A plan has no price per token, so `model.price` stays blank. The log shows tokens with no cost, and only the token [spending limits](../agents/turn-loop.md#stopping) apply.

## Runners

The agent SDK and CLI modes run their own tool loop, so they replace the bridge's agent loop for a turn. The model client stays out of it.

An `AgentRunner` in `src/agents/runner.ts` runs one turn. `runTurn(turn, signal)` takes the system prompt, the turn message, the MCP tools, and the turn limits. It returns how the turn ended and its usage.

The API key and subscription token modes share one runner, the bridge's own loop. Each agent SDK and each CLI adds one.

### Parity check

An agent SDK or a CLI becomes a run mode for a provider only when it does everything the bridge's own loop does:

- replace the system prompt with the one from [prompt.md](../agents/prompt.md#two-calls),
- offer only the bridge's MCP tools, with every built-in tool off,
- load no user or project files, such as `CLAUDE.md` or `AGENTS.md`,
- show each tool call and its input as it happens, so the log has each `reason`,
- end the turn when the agent calls `end_turn`, and keep the [turn limits](../agents/turn-loop.md#failure-handling),
- stop the call in progress on the stop key,
- report each call's input, output, cache read, and cache write tokens, for the spending limits,
- take the model and the effort, and list the models,
- start a fresh context each turn.

### Claude runner

`@anthropic-ai/claude-agent-sdk` passes the check on its docs. The runner calls `query()` with:

- `systemPrompt` set to the system prompt, and the turn message as the prompt,
- `tools: []`, the bridge's MCP server in `mcpServers`, `strictMcpConfig: true`, and `settingSources: []`,
- `PreToolUse` and `PostToolUse` hooks that log each call and count it against the turn limits, and end the run after `end_turn`,
- an `abortController` that the stop key aborts,
- `model` and `effort` from the config file.

The SDK's `total_cost_usd` is an estimate at API prices, not what a plan costs, so the price stays blank, as with a subscription token.

`CLAUDE_AGENT_SDK_ENABLED` in `src/model/run-modes.ts` is `false`, so Anthropic is `flagged` in the agent SDK mode. Anthropic's terms bar a third-party app from offering claude.ai login without approval. The constant becomes `true` once Anthropic approves.

### CLI

No provider uses the CLI mode yet, so its menu row reads `(not available yet)`. The OpenAI subscription token does all that Codex CLI would, and Gemini CLI no longer serves personal accounts.

## Decisions

| Decision | Reason |
| --- | --- |
| Four run modes in one menu, before the provider | Users choose how they pay before what they run. The modes have different sign-ins, and a provider can be in more than one |
| A mode with no ready provider stays in the menu, marked not available | Each mode's step turns it on with one row. Users see what is coming instead of a menu that changes shape |
| The mode table lists providers per mode, each `ready` or `flagged` | A new provider in a mode is one row and one adapter, with no change to the picker |
| A subscription token comes first, then an agent SDK, then a CLI | A token keeps the bridge's own loop, so nothing is lost. An SDK runs its own loop, and a CLI adds a process and output to parse |
| An agent SDK or a CLI must pass the parity check | Users get the same game in every mode. A mode that loses the log, the limits, or the stop key isn't worth offering |
| The Claude flag is a constant in the code, not a config setting | A setting would let anyone turn it on before Anthropic approves, which is the same as offering it. Tests turn it on through injection |
| Plan tokens live in `auth/`, not the config file | Users may share the config file. The refresh token changes on each refresh, and rewriting the config file each hour would risk the user's edits |
| A plan mode leaves the price blank | A plan has no price per token. An estimate at API prices would make cost limits stop runs that cost the user nothing more |
| A usage limit stops the run as a run spending limit does | Every later call fails until the plan resets, and the bridge can't tell when that is. Forced end turns would play turn after turn with no model. A stopped run resumes the same turn on the next start |
