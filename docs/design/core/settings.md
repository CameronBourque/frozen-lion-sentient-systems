# Settings

The bridge's config file: where it lives, what it holds, and what happens when it is missing or wrong. Part of the [bridge](bridge.md).

The bridge reads its settings from `sentient-systems.yaml`, next to the executable. `--config <path>` reads another file, and `npm run dev` passes `tmp/sentient-systems.yaml` at the repo root.

Git ignores `tmp/`. `src/config.ts` holds the `zod` schema, and `src/load-config.ts` finds and reads the file. The file holds settings for the whole bridge:

- `schemaVersion`, which [versioning.md](../versioning.md#bump-rules) requires,
- `logLevel`, one of the five log levels, with `decisions` as the default,
- `providers`, an API key for each provider: `anthropic`, `openai`, `google`, or `xai`, such as `anthropic: { apiKey: "..." }`. A blank key comes from `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, or `XAI_API_KEY` when it is set, and the bridge logs which keys came from there,
- `model`, the model the agents use: `provider`, `id`, `effort`, and `price`, all blank until you pick them. `effort` is one of the AI SDK's reasoning levels, and blank leaves the provider's default.

  `price` has `input`, `output`, `cacheRead`, and `cacheWrite`, in US dollars per million tokens. The cache prices are for input read from or written to the provider's prompt cache. The picker fills it from OpenRouter's public model list, and you can change it. See [picker.md](picker.md#model-facts),
- `mcpPort`, where `--mcp` serves the [MCP server](bridge.md), with `4320` as the default. The game listens on 4318 and 4319 ([protocol.md](../../findings/tuner/protocol.md)), so the default is the next port,
- `journalEntries`, how many of an agent's newest journal entries each turn's [prompt](../agents/prompt.md#two-calls) holds, with `10` as the default.

The schema rejects unknown fields, so a misspelled field is an error instead of a silent default. If the file is missing, the bridge writes a commented example there, names its path, and exits. A bad file exits with one error per field, such as `logLevel: Invalid option`.

A plan's sign-in lives apart from the config file, in `auth/` in the config file's folder. `auth/openai.json` holds the ChatGPT plan's host ID, issued client ID, and tokens, with its own `schemaVersion`, as [subscription-token.md](subscription-token.md) describes.

Never share `auth/`: anyone with a copy can use the plan until the tokens run out. Deleting the file signs the bridge out.

If no provider has a key, the bridge warns and keeps running. Agent slots, personalities, and sweat levels aren't in the file, because they come from the [setup screen](../agents/slot-type.md) and save with the game. The key never goes into a game setup parameter, because saves and multiplayer games share those.

## Decisions

| Decision | Reason |
| --- | --- |
| The config file is YAML next to the executable, with `--config` to read another path | Users edit it by hand, and YAML allows comments that explain each field. Next to the executable, users find it without searching. `--config` keeps a developer's keys under the repo's ignored `tmp/` |
| The `yaml` package parses the config file | It ships its own types and keeps comments when it rewrites a file, which the in-game key box needs. `js-yaml` drops comments when it writes |
| The config file holds only settings for the whole bridge | Agent slots, personalities, and sweat levels belong to a game, so they save with it. A player ID in the config would point at the wrong player after loading another save |
| One API key per provider in `providers` | An agent and its subagents can each use a model from a different provider |
| A blank key comes from an environment variable, and a key in the file wins | A key in the environment stays out of the file, which users may share or show. A key in the file is the one the user chose for the bridge |
| A missing config file gets an example and exits, and an empty key only warns | The example shows every field. Without a terminal, the parts that don't call a model still run with no key. In a terminal, the **Run mode** menu asks again until you pick a mode that can play or **Quit** |
