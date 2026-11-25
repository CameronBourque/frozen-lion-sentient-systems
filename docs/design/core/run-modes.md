# Run modes

How agents reach a model: with an API key, a subscription token, a provider's agent SDK, or a provider's CLI. The picker asks for the run mode first, and each mode lists only the providers that support it. Part of the [bridge](bridge.md).

## Modes

The four run modes differ in who runs the tool loop and how the user signs in.

| Run mode | `RunMode` | Who runs the tool loop | Sign-in | Providers |
| --- | --- | --- | --- | --- |
| **API key** | `api-key` | The bridge's [agent loop](../agents/turn-loop.md), through the [model client](model-client.md) | An API key in `providers` in the [config file](settings.md) | Anthropic, OpenAI, Google |
| **Subscription token** | `subscription` | The bridge's agent loop, through the model client | The provider's browser sign-in for the user's plan | OpenAI, on a ChatGPT plan |
| **Agent SDK** | `agent-sdk` | The provider's agent SDK | The provider's own login for the user's plan | Anthropic, behind a flag |
| **CLI** | `cli` | The provider's CLI, started once per turn | The CLI's own login | None |

For a provider with more than one plan mode, the bridge offers the first that works, in this order:

1. Subscription token, because the bridge keeps its own loop, so every feature works the same as with an API key.
2. Agent SDK, when it passes the [parity check](#parity-check).
3. CLI, when the provider has no agent SDK that passes, and its CLI passes the same check.

[findings/plan-access/](../../findings/plan-access/README.md) has what each provider allows. Google offers no plan mode, so it is API key only.

## Providers

Each provider is one object in its own file in `src/model/providers/`: `anthropic.ts`, `openai.ts`, and `google.ts`. `providers(folder, log)` in `src/model/providers/index.ts` lists them.

It takes the config file's folder and the logger, since OpenAI's token store keeps the plan's tokens in that folder and logs its warnings.

The object's type is `ProviderDef` in `src/model/providers/provider.ts`. It has the provider's name and a `modes` record keyed by `RunMode`. Each entry in `modes` is a `ModeSupport` with these functions:

- `ready(config)`, which says whether the provider can play in that mode, or why not, such as a missing API key,
- `signIn`, only in a subscription token mode, with the `label` of its row in the provider menu, and `run()`, which gets a valid token: the saved one, a refreshed one, or one from the browser sign-in,
- `listModels(config)`, which lists the models for the picker,
- `model(config, id)`, which builds the model for the model client.

A run mode missing from a provider's `modes` isn't available for that provider. An agent SDK or a CLI mode gives its [runner](#runners) in place of `model`.

`credentialMode(name, credential, factory, lister)` in `src/model/providers/mode.ts` builds a `ModeSupport` from three parts:

- a `Credential`, whose `ready` says whether it is ready, `source` gives what a model is built from, and `secret` gives the string a request sends now, or why it can't, such as a refused refresh,
- a factory, which builds the model from the credential's source through the provider's AI SDK package,
- a [lister](model-client.md), which lists the models with the credential's secret. A provider file names each lister and its page shape after the run mode, such as `API_KEY_LISTER` and `SUBSCRIPTION_PAGE`, since one URL may answer in another shape in each mode.

`apiKeyMode(name, factory, lister)` in `src/model/providers/api-key.ts` uses `apiKeyCredential`, whose source and secret are both the key in `providers`, as [settings.md](settings.md) fills it. All three providers use it.

A subscription token's source is a token store, which its factory reads on each request, as `subscriptionMode` in `src/model/providers/openai.ts` does.

To add a provider, add its file and its entry in `providers`. To add a run mode to a provider, add its entry in `modes`, with its sign-in for a subscription token, or its runner for an agent SDK or a CLI.

## Picker

The [picker](picker.md) starts with a **Run mode** menu that lists all four modes and **Quit**, starting on **API key**. **Quit** exits the bridge, as Ctrl+C does, and saves nothing. The bridge doesn't save the run mode, so each start asks again, and one run uses one mode.

The picker finds a mode's providers in two passes over `providers`:

1. The providers that have the mode in `modes`. With none, the mode's row reads `(not available yet)`, and choosing it warns and shows the menu again.
2. Of those, the providers whose `ready` passes, or whose mode has `signIn`, since picking one signs in. With none, the picker warns with the reason, such as no API key, and shows the **Run mode** menu again.

The menus after it depend on the mode:

- **API key.** Provider, model, and effort, as today.
- **Subscription token.** Provider, then the mode's `signIn`, then model and effort from the provider's own list. A signed-out provider's row shows its sign-in label, such as "Continue with ChatGPT". A failed sign-in warns with its reason and shows the **What now?** menu.
- **Agent SDK.** Provider, a login check, then model and effort from the SDK's list.
- **CLI.** Provider, a check that the CLI is installed and logged in, then model and effort.

A provider menu with one provider is skipped, unless that provider needs a sign-in, so the browser never opens before the user picks its row.

When the sign-in or the model list fails, the **What now?** menu offers **Pick another run mode**, which goes back to the **Run mode** menu, beside **Pick another provider**, which stays in the same mode.

The exe always runs in a console, so the picker has a terminal to ask in. Without one, such as when another program pipes the bridge's input, the bridge uses API key mode with the saved model.

## Subscription token

The bridge's loop and the model client stay the same, and the provider model gets a token in place of an API key. OpenAI's ChatGPT plan usage is the one provider. [subscription-token.md](subscription-token.md) has the sign-in, the refresh, and the calls.

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

`CLAUDE_AGENT_SDK_ENABLED` in `src/model/providers/anthropic.ts` is `false`. While it is, Anthropic's `modes` has no agent SDK entry, so the mode reads `(not available yet)`.

Anthropic's terms bar a third-party app from offering claude.ai login without approval. The constant becomes `true` once Anthropic approves.

### CLI

No provider uses the CLI mode yet, so its menu row reads `(not available yet)`. The OpenAI subscription token does all that Codex CLI would, and Gemini CLI no longer serves personal accounts.

## Decisions

| Decision | Reason |
| --- | --- |
| Four run modes in one menu, before the provider | Users choose how they pay before what they run. The modes have different sign-ins, and a provider can be in more than one |
| A mode with no ready provider stays in the menu, marked not available | Each mode's step turns it on with one entry in a provider's `modes`. Users see what is coming instead of a menu that changes shape |
| Each provider is one object that lists the run modes it supports | A new provider is one file, and a new mode is one entry, with no change to the picker. `credentialMode` shares the code of every mode that uses the bridge's loop with no base class, like the rest of the bridge's plain functions |
| The bridge doesn't save the run mode, and the menu starts on **API key** | How to pay is a choice for each run, and the exe always has a console to ask in. A run mode for each subagent waits for the GUI |
| A subscription token comes first, then an agent SDK, then a CLI | A token keeps the bridge's own loop, so nothing is lost. An SDK runs its own loop, and a CLI adds a process and output to parse |
| An agent SDK or a CLI must pass the parity check | Users get the same game in every mode. A mode that loses the log, the limits, or the stop key isn't worth offering |
| The Claude flag is a constant in the code, not a config setting | A setting would let anyone turn it on before Anthropic approves, which is the same as offering it. Tests turn it on through injection |
| `signIn` is an optional part of `ModeSupport`, and the picker calls it when the mode has one | Only a subscription token mode signs in. A new plan provider is still one entry, with no change to the picker |
| A plan mode leaves the price blank | A plan has no price per token. An estimate at API prices would make cost limits stop runs that cost the user nothing more |
