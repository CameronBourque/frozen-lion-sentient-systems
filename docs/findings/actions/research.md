# Research actions

Status: confirmed. Setting the tech and the civic in research, and refusing a tech or civic the player can't research, are confirmed in a running game with Gathering Storm.

The game calls that the research actions wrap, with the Lua state they run in and what the game checks. The techs and civics the player can research are in [choices/research.md](../choices/research.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. Does a tech the game takes against its prerequisites, such as Bronze Working without Mining, finish on a later turn? The action refuses one, so no code depends on the answer.

## What we know now

### Setting the tech or the civic

`OnChooseResearch` in `Base/Assets/UI/Choosers/ResearchChooser.lua` calls `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.RESEARCH, parameters)`. Confirmed in files.

- `PARAM_TECH_TYPE` is the tech's hash, and `PARAM_INSERT_MODE` is `VALUE_EXCLUSIVE`, which replaces the tech in research.
- `OnChooseCivic` in `Base/Assets/UI/Choosers/CivicsChooser.lua` sends `PlayerOperations.PROGRESS_CIVIC` the same way, with `PARAM_CIVIC_TYPE`.
- The action runs in `SentientSystemsCore_UI`. The request takes effect before the next tuner command, so `GetResearchingTech()` and `GetProgressingCivic()` show the new one at once. Confirmed on Windows on 2026-11-09.
- Neither chooser checks before its request, because each lists only what `CanResearch` or `CanProgress` allows.
- `SetCurrentNode` in `TechTree.lua` and `CivicsTree.lua` sends the path from `GetResearchPath(hash)` or `GetCivicPath(hash)` in the same parameter, with `VALUE_APPEND` while shift is held. Confirmed in files.

### The game's checks

- `UI.CanStartPlayerOperation(playerID, operation, parameters, testOnly)` returned `true` with no reasons for every tech and civic tried, with `testOnly` `true` and `false`. This included a researched tech and a tech whose prerequisite the player lacked.
- `RequestPlayerOperation` took `TECH_BRONZE_WORKING` while the player lacked Mining. `GetResearchingTech()` then returned it, and `GetResearchQueue()` held it alone.
- `GetResearchPath` for the same tech returned Mining, then Bronze Working.
- So the game doesn't refuse a tech or civic the chooser doesn't list. The action checks `CanResearch` or `CanProgress` itself, as the [research choices](../choices/research.md#techs-and-civics) do.
- `GetProgressingCivic()` returned `CIVIC_POLITICAL_PHILOSOPHY` while `HasCivic` returned `true` for it.

## Method

1. Send the file's code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4: first `Scripts/SentientSystemsCore_Research.lua`, then `Scripts/Actions/SentientSystemsCore_ActionsResearch.lua`.
2. Call `setResearch` and `setCivic` from the bridge. After each call, read `GetResearchingTech()` and `GetProgressingCivic()` and look them up in `GameInfo.Technologies` and `GameInfo.Civics`.
3. To see what the game takes, send `UI.RequestPlayerOperation` with a tech that `CanResearch` refuses, then read `GetResearchingTech()` and `GetResearchQueue()`.

## Results

A single-player game with Gathering Storm, on Rome's save on turn 15, in `SentientSystemsCore_UI`, for player 0:

| Call | Result |
| --- | --- |
| `setResearch(TECH_SAILING)`, with Bronze Working in research | `{"ok":true}`. The tech in research became Sailing |
| `setCivic(CIVIC_DRAMA_POETRY)`, with Mysticism in research | `{"ok":true}`. The civic in research became Drama and Poetry |
| `setResearch(TECH_BRONZE_WORKING)`, without Mining | `TECH_BRONZE_WORKING isn't one of the techs you can research now.`, and a pointer to the choice. Nothing changed |
| `setResearch(TECH_POTTERY)`, researched | `You have TECH_POTTERY already.` |
| `setResearch(TECH_NOPE)` | `TECH_NOPE isn't a tech.`, and a pointer to the choice |
| `setCivic(CIVIC_THEOLOGY)`, without its prerequisites | `CIVIC_THEOLOGY isn't one of the civics you can research now.`, and a pointer to the choice |
| `setCivic(CIVIC_CODE_OF_LAWS)`, researched | `You have CIVIC_CODE_OF_LAWS already.` |

Date checked: 2026-11-09.
