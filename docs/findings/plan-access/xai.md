# xAI plan access

Status: unconfirmed. Read from xAI's docs and the docs of tools that use its sign-in on 2026-11-24, with no sign-in or call tested yet.

Whether the bridge may let a user sign in with their X Subscription, such as SuperGrok or X Premium, in place of an xAI API key. Part of [plan access](README.md).

## Questions

1. Does xAI allow an app it hasn't announced to sign users in with their X Subscription, and through which OAuth client?
2. On the X Subscription route, does a call accept a custom system prompt and function tools, and report its token counts?

## What we know now

- **Announced tools.** xAI announced X Subscription sign-in inside OpenCode on 2026-05-21. Other open-source tools, such as OpenClaw, Kilo Code, and T3 Code, use the same sign-in. Source: [grok-opencode](https://x.ai/news/grok-opencode).
- **No path for other apps.** No xAI page we found describes how an app it hasn't announced may use the subscription, or how to register an OAuth client. OpenClaw says it uses "xAI's shared OAuth client". Source: [openclaw xai](https://docs.openclaw.ai/providers/xai).
- **Included usage.** The subscription docs say the weekly pool covers first-party use only, in Grok and Cursor, and name no other app. Source: [usage-limits](https://docs.x.ai/x-subscription/usage-limits).
- **Plans.** Free, Plus at $8 a month, Premium at $30 (4 times Plus), Super at $100 (15 times), and Ultra at $200 (50 times). The docs give no absolute numbers, and the pool resets weekly. Source: [pricing](https://docs.x.ai/x-subscription/pricing).
- **Calls.** OpenClaw sends subscription calls to `https://cli-chat-proxy.grok.com/v1` with the Responses API, and signs in with a device code. No xAI page documents this route, its tools, its usage counts, or its limit errors.
- **Terms.** The terms of service and the acceptable use policy refused our fetches with a 403, so no clause is confirmed.

  A summary from Grok says the policy bars access through "unauthorized automated or non-human means" without defining unauthorized. It also found no published page that answers either question.
- **API key.** The metered API at `api.x.ai` returns HTTP 429 at a rate limit. Source: [consumption-and-rate-limits](https://docs.x.ai/docs/key-information/consumption-and-rate-limits).

## Method

1. To answer question 1, ask xAI whether an open-source app that runs on the user's computer may use the subscription sign-in, and how it gets an OAuth client.
2. To answer question 2, once xAI allows it, sign in with a Plus plan, run `npm run ask`, and check the `model_call` record for tool calls and nonzero input and output tokens.

## Results

None yet.

Date checked: 2026-11-24.
