# Settings

The bridge's config file: where it lives, what it holds, and what happens when it is missing or wrong. Part of the [bridge](bridge.md).

The bridge reads its settings from `sentient-systems.yaml`, next to the executable. `--config <path>` reads another file, and `npm run dev` passes `tmp/sentient-systems.yaml` at the repo root. Git ignores `tmp/`. `src/config.ts` holds the `zod` schema, and `src/load-config.ts` finds and reads the file. The file holds settings for the whole bridge:

- `schemaVersion`, which [versioning.md](../versioning.md#bump-rules) requires,
- `logLevel`, one of the five log levels, with `decisions` as the default,
- `providers`, an API key for each provider, such as `anthropic: { apiKey: "..." }`.

The schema rejects unknown fields, so a misspelled field is an error instead of a silent default. If the file is missing, the bridge writes a commented example there, names its path, and exits. A bad file exits with one error per field, such as `logLevel: Invalid option`. If no provider has a key, the bridge warns and keeps running. Agent slots, personalities, and sweat levels aren't in the file, because they come from the [setup screen](../agents/slot-type.md) and save with the game. The key never goes into a game setup parameter, because saves and multiplayer games share those.

## Decisions

| Decision | Reason |
| --- | --- |
| The config file is YAML next to the executable, with `--config` to read another path | Users edit it by hand, and YAML allows comments that explain each field. Next to the executable, users find it without searching. `--config` keeps a developer's keys under the repo's ignored `tmp/` |
| The `yaml` package parses the config file | It ships its own types and keeps comments when it rewrites a file, which the in-game key box needs. `js-yaml` drops comments when it writes |
| The config file holds only settings for the whole bridge | Agent slots, personalities, and sweat levels belong to a game, so they save with it. A player ID in the config would point at the wrong player after loading another save |
| One API key per provider in `providers` | An agent and its subagents can each use a model from a different provider |
| A missing config file gets an example and exits, and an empty key only warns | The example shows every field. With no key, the parts that don't call a model still run |
