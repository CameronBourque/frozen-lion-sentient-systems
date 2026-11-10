# Research actions

Status: confirmed. Setting and queuing the tech and the civic in research, and the queue moving on when a tech is done, are confirmed in a running game with Gathering Storm.

The game calls that the research actions wrap, with the Lua state they run in and what the game checks. The techs and civics the player can research, and the queue, are in [choices/research.md](../choices/research.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. Does a tech the game takes against its prerequisites, such as Bronze Working without Mining, finish on a later turn? The action always sends the path, so no code depends on the answer.

## What we know now

### Setting the tech or the civic

`OnChooseResearch` in `Base/Assets/UI/Choosers/ResearchChooser.lua` calls `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.RESEARCH, parameters)`, with the tech's hash in `PARAM_TECH_TYPE` and `VALUE_EXCLUSIVE` in `PARAM_INSERT_MODE`. Confirmed in files.

- `OnChooseCivic` in `Base/Assets/UI/Choosers/CivicsChooser.lua` sends `PlayerOperations.PROGRESS_CIVIC` the same way, with `PARAM_CIVIC_TYPE`.
- Neither chooser checks before its request, because each lists only what `CanResearch` or `CanProgress` allows.
- `SetCurrentNode` in `Base/Assets/UI/Screens/TechTree.lua` sends the same request with a path in place of the hash: `GetResearchPath(hash)`, a list of tech indexes from 1.

  The path lists the prerequisites the player lacks first and the tech last. `CivicsTree.lua` does the same with `GetCivicPath(hash)`. Confirmed in files.
- `GetResearchPath` returned `nil` for a researched tech, and a list of one for a tech the player can research now. Confirmed on Windows on 2026-11-09.
- The tree screen takes no click on a researched or an unrevealed node, because `STATUS_ART` makes neither a button. Confirmed in files.
- The action runs in `SentientSystemsCore_UI`. The game handles a request a moment after the tuner command that sends it, so a read in the same command shows the old research. A read 1.5 seconds later showed the new one. Confirmed on Windows on 2026-11-09.

### The queue

- `VALUE_EXCLUSIVE` replaces the queue with the path. `VALUE_APPEND`, which the tree screen sends while shift is held, adds the path to the end and skips the techs already in the queue.
- When the tech in research is done, the next one in the queue starts with no new request.
- `GetResearchQueue()` and `GetCivicQueue()` read the queue. Confirmed on Windows on 2026-11-09.

### The game's checks

- `UI.CanStartPlayerOperation(playerID, operation, parameters, testOnly)` returned `true` with no reasons for every tech and civic tried, with `testOnly` `true` and `false`. This included a researched tech and a tech whose prerequisite the player lacked.
- `RequestPlayerOperation` took the hash of `TECH_BRONZE_WORKING` alone while the player lacked Mining, and the queue held Bronze Working alone. With `VALUE_APPEND`, it added `TECH_HORSEBACK_RIDING` without Animal Husbandry.
- A researched tech sent with `VALUE_APPEND` changed nothing.
- So the game doesn't refuse a tech or civic out of order. The action sends the path from `GetResearchPath` or `GetCivicPath`, as the tree screen does.
- `GetProgressingCivic()` returned `CIVIC_POLITICAL_PHILOSOPHY` while `HasCivic` returned `true` for it. Confirmed on Windows on 2026-11-09.

## Method

1. Send the file's code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4. Send `Scripts/SentientSystemsCore_Research.lua` first, then the research choices, trees, and actions files.
2. Call `setResearch`, `setCivic`, `queueResearch`, and `queueCivic` from the bridge. Wait 1.5 seconds, then read `GetResearchQueue()` and `GetCivicQueue()`, and look up each index in `GameInfo.Technologies` and `GameInfo.Civics`.
3. To see the queue move on, append a tech after a tech that is 1 turn from done. End the turn as in [actions/end-turn.md](end-turn.md), then read the queue.
4. To see what the game takes, send `UI.RequestPlayerOperation` with a tech's hash alone, for a tech that `CanResearch` refuses.

## Results

A single-player game with Gathering Storm, on Rome's save on turn 15, in `SentientSystemsCore_UI`, for player 0:

| Call | Result |
| --- | --- |
| `setResearch(TECH_SAILING)`, with Bronze Working in research | `{"ok":true}`. The tech in research became Sailing |
| `setCivic(CIVIC_DRAMA_POETRY)`, with Mysticism in research | `{"ok":true}`. The civic in research became Drama and Poetry |
| `setResearch(TECH_IRON_WORKING)` | `{"ok":true}`. The queue became Mining, Bronze Working, and Iron Working |
| `queueResearch(TECH_MATHEMATICS)` | `{"ok":true}`. Currency and Mathematics went to the end |
| `queueResearch(TECH_BRONZE_WORKING)` | `{"ok":true}`, and the queue didn't change, as it held Mining and Bronze Working |
| `setCivic(CIVIC_THEOLOGY)`, then `queueCivic(CIVIC_GAMES_RECREATION)` | The queue became Drama and Poetry, Mysticism, Theology, and Games and Recreation |
| `setResearch(TECH_POTTERY)`, researched | `You have TECH_POTTERY already.` |
| `setResearch(TECH_NOPE)` | `TECH_NOPE isn't a tech.`, and a pointer to the choice |
| `setCivic(CIVIC_CODE_OF_LAWS)`, researched | `You have CIVIC_CODE_OF_LAWS already.` |

With Sailing 1 turn from done, `queueResearch(TECH_MINING)` gave the queue Sailing and Mining. After ending turn 15, Sailing was researched, and the queue held Mining alone, in research.

Date checked: 2026-11-09.
