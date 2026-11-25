# xAI provider

Add xAI as a fourth provider in the **API key** run mode, so Grok models are a choice beside Anthropic, OpenAI, and Google. The design is in [run-modes.md](../../design/core/run-modes.md#providers). Part of [phase 2](README.md).

xAI's plan sign-in is not part of this step. It waits on xAI's answer to question 1 in [plan-access/xai.md](../../findings/plan-access/xai.md).

## Tasks

1. **Provider.** Add `src/model/providers/xai.ts` with an API key mode built on `@ai-sdk/xai`, like `google.ts`. Add `xai` to `PROVIDER_NAMES` and `XAI_API_KEY` to the key variables, and list the provider in `src/model/providers/index.ts`.

   Its lister reads xAI's model list with the key. Test it with a recorded reply, as the other listers are tested. Commit: `feat(core): add xAI as a provider`.

## Done when

All of these hold:

- With `XAI_API_KEY` set, the picker offers xAI in the **API key** mode and lists its Grok models.
- `npm run ask` with a Grok model answers, and its `model_call` record has nonzero input and output tokens.

## Record

- xAI in the provider lists in [model-client.md](../../design/core/model-client.md), [run-modes.md](../../design/core/run-modes.md#providers), and [settings.md](../../design/core/settings.md).
- Any way xAI's model list or usage differs from the other providers, in [model-client.md](../../design/core/model-client.md).
