# Plan access

Which providers let the bridge use a user's paid plan, such as ChatGPT Plus or Claude Max, in place of an API key, and through what: a token for the provider's API, an agent SDK, or a CLI. [design/core/run-modes.md](../../design/core/run-modes.md) uses these facts. See the [findings index](../README.md).

| File | Topic |
| --- | --- |
| [openai.md](openai.md) | OpenAI lets an open-source app use a ChatGPT plan through a token for its API, with a browser sign-in |
| [anthropic.md](anthropic.md) | Anthropic's Claude Agent SDK can use a Claude plan, but a third-party app needs Anthropic's approval first |
| [google.md](google.md) | Google offers no plan access to third-party apps, so it is API key only |
