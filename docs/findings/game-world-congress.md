# Game World Congress calls

Status: open. The `worldCongress` key of `SentientSystems_GetChoices`, what the player decides in a World Congress session and looks at when one has ended, is confirmed in a running game with Gathering Storm for a regular session, a Special Session, and the results screen, and matches each screen. The results of a session's proposals are left out.

The calls the congress choice uses, as the congress screen shows them. The emergencies the congress calls are in [game-emergencies.md](game-emergencies.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. What do the review's `Discussions` hold, the results of the proposals that were voted on in a session? They were empty in the results checked, so the choice leaves them out.

## What we know now

### Congress screen

`DLC/Expansion2/UI/Additions/WorldCongressPopup.lua` draws the congress screen. `SetStage`, lines 164 to 246, picks what it shows from the congress's stage. Stage 1 is a regular session, 2 a Special Session, and 4 the screen out of a session, with three tabs: **Last Session Results**, **Active Effects**, and **Available Proposals**. `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` is up in a session, and `ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK` is up to look at the results. Confirmed in files and on Windows on 2026-10-29.

- **Resolutions.** `Game.GetWorldCongress():GetResolutions(playerID)` lists them in a session, each with `Type`, a hash that `GameInfo.Resolutions` takes, `TargetType`, such as `ResourceType`, `GreatPersonClassType`, or `PlayerType`, `PossibleTargets`, a numbered list of text keys or player IDs, and `FavoredPlayerIDs` and `DisfavoredPlayerIDs`. The row has `Name`, `Effect1Description`, and `Effect2Description`, the outcomes A and B. The calls need the player's ID: without it the game returned empty lists. Confirmed in files and on Windows on 2026-10-29.
- **Votes.** `GetVotesandFavorCost(playerID)` is the cumulative Favor by number of votes, and `MaxVotes`. A player can cast `n` votes for `kCostData[n - 1]` Favor, so the first vote is free. The most votes were 8, then 10 with Diplomatic Service, then 13 with more Favor. For each resolution the player picks one outcome, a target, and a number of votes, with the other outcome's votes at 0. Confirmed in files and on Windows on 2026-10-29.
- **Submitting.** `OnAccept`, lines 2222 to 2318, sends `PlayerOperations.WORLD_CONGRESS_RESOLUTION_VOTE` for each resolution with `PARAM_RESOLUTION_TYPE`, the type's hash, `PARAM_WORLD_CONGRESS_VOTES`, `PARAM_RESOLUTION_OPTION`, 1 or 2, and `PARAM_RESOLUTION_SELECTION`, the target's index minus 1. It sends `WORLD_CONGRESS_DISCUSSION_VOTE` for each proposal, with `PARAM_PLAYER_ONE` the sender, `PARAM_PLAYER_TWO` the target, and the votes, negative against. Then it sends `WORLD_CONGRESS_SUBMIT_TURN` and ends the turn. Confirmed in files.
- **Proposals.** `GetProposals(playerID).Proposals` holds the proposals on the floor, in categories, each with `ProposalsOfType`. Each has `TypeName`, `Name`, `Description`, `Sender`, `Target`, and `EmergencyType`. The Special Session had only proposals, so the choice calls a session with no resolutions `special`. Confirmed in files and on Windows on 2026-10-29.
- **Calling a Special Session.** Out of a session, `GetEmergencies(playerID).Proposals` lists what the player could call one for, each category with `FavorCost`, 30, and each proposal with `Disabled`. The player picks them and submits with `WORLD_CONGRESS_DISCUSSION_SELECTION`, with `PARAM_OTHER_PLAYER` the target and `PARAM_DISCUSSION_TYPE` the type, which costs the Favor and starts the session on a later turn. Confirmed in files and on Windows on 2026-10-28.
- **Results.** `GetReview(playerID).Resolutions` lists the last session's resolutions, each with `Type`, `ChosenLabel`, `ChosenOption`, `ChosenThing`, `RejectedLabel`, `RejectedOption`, `TargetType`, `Winner`, and `PlayerSelections`, each with `PlayerID`, `OptionChosen`, `OptionChosenLabel`, `OptionChosenDescription`, `Votes`, and `ResolutionTarget`, which the screen lists for each player when the result is expanded. A tie shows as passed with a note. Confirmed in files and on Windows on 2026-10-28.
- **Active effects.** Out of a session, `GetResolutions(playerID)` returns the resolutions in effect, with `ChosenLabel`, `ChosenOption`, and `ChosenThing`, and the screen shows `GetMeetingStatus().TurnsLeft + 1` turns left for each. Confirmed in files and on Windows on 2026-10-28.
- **Schedule.** The regular session came 14 turns of ending the turn after the one that `TurnsLeft` read 15 on. `Game.SetCurrentGameTurn` doesn't move it, and `TurnsLeft` read 0 for several turns before the session came. Confirmed on Windows on 2026-10-29.

## Method

1. For a regular session, end turns until `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` is up, and read the choice before voting. Giving the player Favor in `GameCore_Tuner` raises the most votes.
2. For a Special Session, with the war between allies, see [game-emergencies.md](game-emergencies.md).

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| A Special Session with the Aid Request on the floor, 196 Favor | `session` special, `proposals` holding `WC_EMERGENCY_REQUEST_AID`, `sender` 11, `target` 11, and `resolutions` empty, with 10 vote costs from 0 to 180 |
| The regular session on turn 85, 335 Favor | `session` regular, 13 vote costs from 0 to 312, and two resolutions. **Patronage**, `WC_RES_PATRONAGE`, with the target type `GreatPersonClassType`, 8 targets from Great General to Great Musician, `favored` 5 and 11, and `disfavored` 4. **Trade Policy**, `WC_RES_TRADE_TREATY`, with `PlayerType`, 12 targets, the players 0 to 11 by their names, `favored` 1 and 7. The screen showed the favored count under outcome A and the disfavored count under B, so `favored` leans to A and `disfavored` to B |
| The review at the results blocker, and the effects | `GetReview(playerID)` held the last two resolutions, Luxury Policy, B 52 to A 3, and Border Control Treaty, A 22 to B 1, with 18 turns left for each, as the screens showed |
| The results screen after the regular session | `session` review, `results` Patronage, B elected, target Great Writer, votes A 4 and B 30, and Trade Policy, A elected, target Ambiorix, A 35 and B 0, and `effects` with the same two and `turnsLeft` 20, as the screen showed, with "reconvene in 20 turns". The expanded Patronage result listed 12 voters, such as player 0 for A with 1 vote on Great General and player 1 for B with 8 on Great Writer, which the player selections matched. The blocker clears once the screen opens, so the choice was run with its gate bypassed, as the emergency choice was |

Date checked: game files on 2026-10-29. Running game on Windows on 2026-10-29.
