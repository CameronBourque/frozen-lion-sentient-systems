# Knowledge and personality files

Agents learn the game from files and the Civilopedia, not from web research. The files fall into layers, split by who maintains each one and how. Game facts are never in files. The agent looks them up at runtime.

## Layers

| Layer | Contents | Maintained by |
| --- | --- | --- |
| Concept guides | Strategy for any civ: expansion, district planning, eurekas, and archetypes such as domination or faith civs | Hand-written, tuned by trial and error |
| Civ notes | Strategy for one civ: its ability, leader, unique units, and unique buildings | Shipped for Gathering Storm civs. Generated and cached for other civs |
| Opening books | Plans for the first turns of a game, as trees that branch. See [decision-support/opening-books.md](decision-support/opening-books.md) | Hand-written, tuned from decision records |
| Personalities | Priorities, behavior rules, narrator voice | Hand-written. The game's leader agendas are a starting point |
| Sweat levels | The mindset for each level. See [agents/sweat-level.md](agents/sweat-level.md) | Hand-written, tuned from logs and playtests |

When the agent needs a stat, a requirement, or a rule, it calls the `search_civilopedia` and `read_civilopedia` tools.

Concept guides hold judgment, and [decision helpers](decision-support/helpers.md#helpers-and-knowledge-files) hold arithmetic. A guide says when to call a helper and what the helper cannot judge.

## Civ notes

The mod ships notes for every Gathering Storm civ. A script generates them from the Civilopedia once, and you review them.

When an agent meets a civ with no note, such as a modded civ, it writes one from that civ's Civilopedia and database entries. The bridge caches that note locally for later games.

An agent uses the first note it finds, in this order:

1. A file in the `overrides/` folder. The mod ships this folder empty.
2. The note shipped with the mod.
3. The generated note in the local cache.

Mod authors do not need a special format. A better Civilopedia entry gives a better generated note, and it helps human players too. Advisors use the same notes.

## File layout

The files live in `packages/core/bridge/knowledge/`, because the bridge reads them to build the prompt. The executable carries them, so a user installs nothing next to it.

The game's Lua has no `io`, as [lua/dialect.md](../findings/lua/dialect.md) shows, so the agent players mod can't read the files. When the setup screen gets its personality and sweat level dropdowns, a script generates their options from these folders into the agent players mod.

A personality or sweat level file is plain Markdown. Its body goes into the prompt as it is. `rules/play.md` holds the rules of play that every agent gets. [prompt.md](agents/prompt.md) says how the files become the prompt.

```
concepts/
civ-notes/
openings/
overrides/
rules/
	play.md
personalities/
	neutral.md
	warmonger.md
	builder.md
	zealot.md
sweat/
	no-sweat.md
	balanced.md
	super-sweat.md
```

`neutral.md` has no slant in its priorities. Runs that compare models or measure [skill](evaluation.md) use it, so the personality doesn't skew the numbers.

An agent at runtime is a slot ID, a personality file, a sweat level, and a memory folder. There are no separate agent definitions and no subagents for strategy, tactics, or narration. A deep strategic review with a stronger model is a mode inside the same agent loop, and it uses the same memory.

## Decisions

| Decision | Reason |
| --- | --- |
| No separate agent definitions or subagents | Personality plus sweat level defines an agent |
| The knowledge files live in the bridge, and the executable carries them | The bridge is the only part that reads them. A change to a file releases core, which rebuilds the executable |
| Generate the setup screen's dropdown options from the knowledge files | The game's Lua can't read the files, and one home for the list keeps the dropdowns and the bridge in step |
| Personality and sweat level files are plain Markdown with no frontmatter | Their body is prompt text. Weights for the [decision helpers](decision-support/helpers.md#weights) get a format when a helper reads them |
| Ship a neutral personality | Baseline runs need a personality that doesn't push the agent toward one victory or playstyle |
| Ship civ notes for Gathering Storm civs, generate the rest | The base game gets reviewed notes, and a modded civ still gets a note |
| Empty `overrides/` folder for hand-written civ notes | Curated notes without asking mod authors for anything |
| Mod authors improve agent play through Civilopedia entries | The same text helps human players |
