# Google plan access

Status: unconfirmed. Read from Google's docs and forum on 2026-11-22.

Why the bridge offers no plan mode for Google: its CLIs and SDK bar use from third-party apps. Part of [plan access](README.md).

## Questions

None.

## What we know now

- **Gemini CLI.** Since 2026-06-18, Gemini CLI serves only Gemini Code Assist Standard and Enterprise licenses. Free personal use and Google AI Pro and Ultra moved to Antigravity CLI. Source: [gemini-cli README](https://github.com/google-gemini/gemini-cli).
- **Terms.** Using the services behind Gemini CLI from third-party software violates Google's terms. Source: [tos-privacy](https://geminicli.com/docs/resources/tos-privacy/).
- **Antigravity SDK.** Python only. Source: [antigravity-sdk](https://antigravity.google/product/antigravity-sdk).
- **Antigravity CLI.** The FAQ says using third-party software, tools, or services to access Antigravity violates the terms, and can lead to suspension. It points third-party coding agents to a Vertex or AI Studio API key. Source: [faq](https://antigravity.google/docs/faq).

  Headless mode (`agy -p`) is for the user's own scripts and CI. Forum replies disagree on whether another app may launch it, and none covers an app that replaces its prompt and tools for other users, as the bridge would. Source: [forum thread](https://discuss.ai.google.dev/t/is-it-allowed-for-an-open-source-tool-to-call-the-official-agy-cli-in-headless-mode/183429).

## Method

Read Google's terms, FAQ, and forum. Nothing here needs a test, since no plan mode depends on it.

## Results

None.

Date checked: 2026-11-22.
