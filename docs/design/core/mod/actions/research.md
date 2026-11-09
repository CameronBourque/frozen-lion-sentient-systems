# Research actions

How the core mod runs the actions that set the tech and the civic in research. Part of the [action API](README.md).

## Techs and civics

`SentientSystems_SetResearch(playerID, tech)` and `SentientSystems_SetCivic(playerID, civic)` in `Scripts/Actions/SentientSystemsCore_ActionsResearch.lua` replace the tech or the civic in research, as the chooser does.

The tech or civic is the `type` of an option of the `techs` or `civics` choice, such as `TECH_MINING`.

Both are one-line wrappers around one action, `ChooseResearch`. It reads the kind's calls from `SENTIENTSYSTEMS_RESEARCH_KINDS` in `Scripts/SentientSystemsCore_Research.lua`, the table that the research choices and the research trees read too.

`SentientSystems_IsResearchOption` in the same file decides what the chooser lists, for the choice and the action alike.

The game takes a request for any tech or civic, so the action makes the chooser's check itself. See [research.md](../../../../findings/actions/research.md).

Its reasons, in order, name a type that is no tech or civic, a tech or civic the player has already, and one the player can't research now. The first and the last point at the choice.

On the bridge, `setResearch` and `setCivic` in `src/actions/research.ts` share one helper, `sendResearch`.

## Decisions

| Decision | Reason |
| --- | --- |
| Techs and civics share one table of calls, one check, and one action | The two choosers differ only in the calls they make, so a fix to one kind reaches the other, and the choice and the action can't disagree on what is legal |
| The action allows only what the chooser lists, the tech in research or one that `CanResearch` or `CanProgress` allows | The game's own check allows every tech and civic, and takes one whose prerequisites the player lacks |
| A tech or civic the player has gets its own reason | The agent learns it has the tech already, not only that the tech isn't an option |
