# Research actions

How the core mod runs the actions that set and queue the tech and the civic in research. Part of the [action API](README.md).

## Techs and civics

`SentientSystems_SetResearch(playerID, tech, append)` and `SentientSystems_SetCivic(playerID, civic, append)` in `Scripts/Actions/SentientSystemsCore_ActionsResearch.lua` research a tech or a civic and the prerequisites it needs, as a click on the tree screen does.

The tech or civic is a `type` from the `techs` or `civics` choice, or from the tech or civic tree, such as `TECH_MINING`. Without `append` the path replaces the queue. With `append` it goes to the end, as a shift-click does, and the game skips what is queued already.

Both are one-line wrappers around one action, `ChooseResearch`. It reads the kind's calls from `SENTIENTSYSTEMS_RESEARCH_KINDS` in `Scripts/SentientSystemsCore_Research.lua`, the table that the research choices and the research trees read too.

The game takes a request for any tech or civic, even out of order, so the action always sends the path from `GetResearchPath` or `GetCivicPath`. See [research.md](../../../../findings/actions/research.md).

Its reasons, in order, name a type that is no tech or civic, a tech or civic the player has already, one the tree doesn't reveal yet, and one the game finds no path to. The first and the third point at the choice or the tree.

The choice and the tree give each queued tech or civic its place in the queue, so the agent sees what it queued.

On the bridge, `setResearch` and `setCivic` in `src/actions/research.ts` share one helper, `sendResearch`, and take `append` as an option.

## Decisions

| Decision | Reason |
| --- | --- |
| Techs and civics share one table of calls and one action | The choosers and tree screens differ only in the calls they make, so a fix to one kind reaches the other |
| The action sends the tree screen's path for every tech or civic, an option or a later one | One request covers both, and the game takes a tech out of order when it gets a hash alone |
| The action takes a type from the tree, not only from the choice | The agent can plan several techs ahead, as a player does on the tree screen |
| A researched or unrevealed tech or civic gets its own reason | The tree screen takes no click on either, and the agent learns which case it hit |
| Queuing is an `append` flag on the same action, not an action of its own | The request differs only in its insert mode, as the tree screen's click and shift-click do |
