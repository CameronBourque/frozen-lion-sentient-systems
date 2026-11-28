# Phase 2: model steps

The finished steps of [phase 2](../README.md) that reach the models: the model client, the run modes, and the providers. The step table's `#` column sets their order.

## Model client

Pull request: feat(core): add the model client.

It added the model client, which calls Anthropic, OpenAI, or Google through the Vercel AI SDK, and a picker that asks for the provider, the model, and the effort when the bridge starts.

Each model's price, tool support, and effort levels come from OpenRouter's public model list. Each call logs its tokens and cost, and retries a rate limit or a server error. `npm run ask` returned a tool call from each provider, and a refused key named its config field.

- The client, the providers, the model list, the failures, and `npm run ask` are in [design/core/model-client.md](../../../design/core/model-client.md). The picker and the prices are in [design/core/picker.md](../../../design/core/picker.md).
- The `providers` and `model` fields, and the environment variables that fill a blank key, are in [design/core/settings.md](../../../design/core/settings.md).

## Run mode menu

Pull request: feat(core): add the run mode menu.

It moved each provider into its own file in `src/model/providers/`, listed in `PROVIDERS`, and added a **Run mode** menu before the provider menu. The menu lists the four run modes and **Quit**, starting on **API key**, and only **API key** plays.

A mode that no provider has reads `(not available yet)`. **What now?** gained **Pick another run mode**, and the `model_chosen` log line names the run mode. The bridge doesn't save the run mode.

`npm run ask` passed every case in a terminal on 2026-11-23.

- The provider files and the menu's rules are in [design/core/run-modes.md](../../../design/core/run-modes.md#providers).
- The menus, in order, are in [design/core/picker.md](../../../design/core/picker.md#menus).

## ChatGPT plan

Pull request: feat(core): run agents on a ChatGPT plan.

It turned on the **Subscription token** run mode for OpenAI. Picking **Continue with ChatGPT** signs in through the browser, and the bridge saves the tokens in `auth/openai.json`, refreshes them before they expire, and calls OpenAI's API with them.

Each plan error code is its own failure kind, and a plan model has no price, so its calls log no cost. The repo is now under the Apache License 2.0.

On 2026-11-25, `npm run ask` signed in on a ChatGPT Plus plan, listed the plan's models with no prices, and printed the tool call. Its `model_call` record had 85 input and 20 output tokens and no cost. Once the access token expired, the next run refreshed it with no browser.

In the API key mode it printed the tool call for Anthropic. OpenAI and Google wait for an API key to check.

- The sign-in, the tokens, the refresh, and the calls are in [design/core/subscription-token.md](../../../design/core/subscription-token.md).
- The credential, `subscriptionMode`, and the picker's sign-in row are in [design/core/run-modes.md](../../../design/core/run-modes.md#providers).
- The failure kinds are in [design/core/model-client.md](../../../design/core/model-client.md#failures), and `auth/` is in [design/core/settings.md](../../../design/core/settings.md).
- The live check's results are in [findings/plan-access/openai.md](../../../findings/plan-access/openai.md#results), and the license and why are in [design/distribution.md](../../../design/distribution.md).

## xAI provider

Pull request: feat(core): add xAI as a provider.

It added xAI as a fourth provider in the **API key** mode, through `@ai-sdk/xai`, with `XAI_API_KEY` for a blank key. Its model list reads `/v1/language-models`, which leaves out xAI's image and video models. xAI's plan sign-in waits on xAI's answer in [findings/plan-access/xai.md](../../../findings/plan-access/xai.md).

The saved model now keeps the run mode it was picked in, as `model.mode`. After a failed list, **Use** runs it in that mode, so a model picked on a ChatGPT plan no longer runs on a refused API key. The picker's design moved to its own file.

On 2026-11-25, `npm run ask` named a refused OpenAI key's config field, and **Use** ran the saved plan model on the plan. The xAI list and a Grok call wait for an xAI API key to check.

- The xAI lister is in [design/core/model-client.md](../../../design/core/model-client.md#model-lists), and its key is in [design/core/settings.md](../../../design/core/settings.md).
- The saved run mode and **Use** are in [design/core/run-modes.md](../../../design/core/run-modes.md#picker), and the menus are in [design/core/picker.md](../../../design/core/picker.md#menus).

## Anthropic Agent SDK runner

Pull request: feat(core): run Claude agents through the Agent SDK.

Each run mode now builds an `AgentRunner` that plays a turn's tool calls, and the runners share each call's steps, the spend, and the nudge. The API key and subscription token modes keep the bridge's own loop, in `modelClientRunner`.

The **Agent SDK** mode for Anthropic plays a turn through the Claude Agent SDK's own loop, with hooks that keep the bridge's limits and logs. It sits behind `CLAUDE_AGENT_SDK_ENABLED`, which stays `false` until Anthropic approves plan logins.

A mode with a plan login of its own gets a **Sign-in** menu when the provider's API key is ready too.

On 2026-11-28, a local build with the flag on played turns on `haiku` with an API key, and logged each action with its reason and each round with its tokens.

The SDK listed no built-in tool, an `AGENTS.md` in the memory folder never reached the model, and Ctrl+C during a turn exited within 6 seconds.

- The runners and their shared steps are in [design/agents/turn-loop/](../../../design/agents/turn-loop/README.md#runners), and each mode's runner in [design/core/run-modes.md](../../../design/core/run-modes.md#runners).
- The SDK's options, hooks, spend, sign-in, and flag are in [design/core/anthropic-agent-sdk-runner.md](../../../design/core/anthropic-agent-sdk-runner.md), and the **Sign-in** menu in [design/core/picker.md](../../../design/core/picker.md#plan-login).
- The tools check and the live turns are in [findings/plan-access/anthropic.md](../../../findings/plan-access/anthropic.md#results). The AGENTS.md check used a marker word in place of the input tokens, which varied with each turn's calls.
