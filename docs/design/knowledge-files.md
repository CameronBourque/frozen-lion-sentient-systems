# Knowledge and personality files

Agents learn the game from files and the Civilopedia, not from web research. The files fall into layers, split by who maintains each one and how. Game facts are never in files. The agent looks them up at runtime.

## Layers

| Layer | Contents | Maintained by |
| --- | --- | --- |
| Concept guides | Strategy for any civ: expansion, district planning, eurekas, and archetypes such as domination or faith civs | Hand-written, tuned by trial and error |
| Civ notes | Strategy for one civ: its ability, leader, unique units, and unique buildings | Shipped for Gathering Storm civs. Generated and cached for other civs |
| Personalities | Priorities, behavior rules, narrator voice | Hand-written. The game's leader agendas are a starting point |
| Sweat levels | The mindset for each level. See [agents/sweat-level.md](agents/sweat-level.md) | Hand-written, tuned from logs and playtests |
| Model table | The model for each provider and operation | `models.yaml`, filled by testing |

When the agent needs a stat, a requirement, or a rule, it calls the Civilopedia `lookup` tool.

## Civ notes

The mod ships notes for every Gathering Storm civ. A script generates them from the Civilopedia once, and you review them. When an agent meets a civ with no note, such as a modded civ, it writes one from that civ's Civilopedia and database entries. The bridge caches that note locally for later games.

An agent uses the first note it finds, in this order:

1. A file in the `overrides/` folder. The mod ships this folder empty.
2. The note shipped with the mod.
3. The generated note in the local cache.

Mod authors do not need a special format. A better Civilopedia entry gives a better generated note, and it helps human players too. Advisors use the same notes.

## File layout

```
concepts/
civ-notes/
overrides/
personalities/
	warmonger.md
	builder.md
	zealot.md
sweat/
	no-sweat.md
	balanced.md
	super-sweat.md
models.yaml
```

An agent at runtime is a slot ID, a personality file, a sweat level, and a memory folder. There are no separate agent definitions and no subagents for strategy, tactics, or narration. A deep strategic review with a stronger model is a mode inside the same agent loop, and it uses the same memory.

## Decisions

| Decision | Reason |
| --- | --- |
| No separate agent definitions or subagents | Personality plus sweat level defines an agent |
| Ship civ notes for Gathering Storm civs, generate the rest | The base game gets reviewed notes, and a modded civ still gets a note |
| Empty `overrides/` folder for hand-written civ notes | Curated notes without asking mod authors for anything |
| Mod authors improve agent play through Civilopedia entries | The same text helps human players |
