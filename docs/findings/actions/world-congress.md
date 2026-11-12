# World Congress actions

Status: open. Voting on a Special Session's proposal and on a regular session's resolutions, and making a proposal, are confirmed in a running game with Gathering Storm, with the files sent through the tuner.

The game calls that the World Congress actions wrap, with the Lua state each runs in and what the game checks. What the player sees in a session is in [choices/world-congress.md](../choices/world-congress.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. Does the game check a vote's Favor itself, or only the screen?
2. Why does the game take only the costliest item's Favor at the submit, when the screen adds up every item's cost? Is the rest taken when the session ends?

## What we know now

### Proposal vote

`OnAccept` in `DLC/Expansion2/UI/Additions/WorldCongressPopup.lua` sends one `UI.RequestPlayerOperation(playerID, PlayerOperations.WORLD_CONGRESS_DISCUSSION_VOTE, parameters)` for each proposal on the floor.

The parameters hold the proposal's sender in `PARAM_PLAYER_ONE`, its target in `PARAM_PLAYER_TWO`, and the votes in `PARAM_WORLD_CONGRESS_VOTES`, negative to vote against. The proposal's type isn't sent. Confirmed in files.

It then sends `WORLD_CONGRESS_SUBMIT_TURN` with no parameters, and `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`. Confirmed in files.

### Resolution vote

In a regular session, `OnAccept` first sends one `WORLD_CONGRESS_RESOLUTION_VOTE` for each resolution, before the proposal votes. The parameters hold:

- the resolution's `GameInfo.Resolutions` hash in `PARAM_RESOLUTION_TYPE`
- the votes in `PARAM_WORLD_CONGRESS_VOTES`
- the option in `PARAM_RESOLUTION_OPTION`, 1 for A and 2 for B
- the target's place in `PossibleTargets`, counting from 0, in `PARAM_RESOLUTION_SELECTION`

The player votes for one option of each resolution: voting for one clears the votes on the other, in `OnVoteResolution`. Confirmed in files.

`CanMoveToNextPhase` won't let the player go on until every resolution has at least 1 vote with an option and a target, and every proposal has a vote, unless its voting blocker allows neither side. Confirmed in files.

`GameInfo.VotingBlockers` has five rows. A target of a hostile emergency can't vote for it, a target of a friendly one can't vote against it, and a player who hasn't met the target or wasn't invited to the emergency can't vote at all. Confirmed on Windows on 2026-11-11.

### Proposal

Out of a session, `OnAccept` sends one `WORLD_CONGRESS_DISCUSSION_SELECTION` for each proposal the player ticked on the Available Proposals tab, after a confirmation. The parameters hold the target in `PARAM_OTHER_PLAYER` and the proposal's `Type` in `PARAM_DISCUSSION_TYPE`.

`Type` is the hash of the proposal's row, `GameInfo.Discussions[TypeName].Hash`: -789239900 for `WC_EMERGENCY_REQUEST_AID`. Confirmed in files and on Windows on 2026-11-11.

`OnToggleProposal` lets the player tick a proposal only while the Favor left covers its category's `FavorCost`. Closing the screen out of session sends `WORLD_CONGRESS_LOOKED_AT_AVAILABLE` with no parameters, which the game uses to clear the congress's blocker. See `ClosePopup`. Confirmed in files.

Within 3 seconds of the request, the Favor was down by the cost and the proposal read `Disabled`, with a `ProposalBlockerType` that is a hash, not a row's index. The proposal didn't show in `GetProposals` until the session.

The screen still offered the proposal until the turn ended, and the `WORLD_CONGRESS_EMERGENCY_CAN_BE_CALLED` and `SPECIAL_SESSION_CAN_BE_CALLED` notifications stayed up. The screen dismisses them through `LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification`.

The Special Session met on the next turn, with the proposal on the floor and the player as its sender. Confirmed on Windows on 2026-11-11.

### Favor

`GetVotesandFavorCost(playerID)` gives the cost of each number of votes, with the cost of n votes at index n - 1, and `MaxVotes`. Each proposal's votes cost what the list gives for that many, and the screen adds them up against `GetFavor()`. See `OnVoteProposal`. Confirmed in files.

`MaxVotes` follows the player's Favor at the time: the most votes whose cost the Favor covers. It was 23 at 1,032 Favor, 4 at 32, and 55 at 6,032, after `GetDiplomacy():ChangeFavor` in `GameCore_Tuner`. Confirmed on Windows on 2026-11-11.

So one item can't cost more than the player has, and the action's cost reason only comes up for votes on several items.

Right after the submit, the Favor went down by the cost of the costliest item, not the sum. With 10 votes on one resolution and 5 on the other, in either order, it went down by 220, the cost of 10. Confirmed on Windows on 2026-11-11.

The action checks the sum, as the screen does, so it refuses no votes the game would take for less.

The screen's tooltip says that some of the Favor spent on resolutions comes back when the congress doesn't agree with the player's choice. Confirmed in files and on Windows on 2026-11-11.

### What the request does

In `SentientSystemsCore_UI`, within 3 seconds of the votes and the submit, `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` was gone and the Favor was down by the votes' cost. The congress was still in session until the turn ended. The submit alone cleared the blocker, without the end turn request.

On the next turn, the Betrayal Emergency had passed and begun, with no blocker. Confirmed on Windows on 2026-11-11.

After a regular session, the review's `PlayerSelections` held the action's option, target, and votes for each resolution. Confirmed on Windows on 2026-11-11.

### A second submit

The voting screen stays open after the action submits. Voting there and pressing **Submit** replaced the action's votes with the screen's, and the Favor the action spent didn't come back. Confirmed on Windows on 2026-11-11.

### Popups

The congress screen opened with **Continue** and then showed the voting screen, though the action had voted. Closing it with **X** let the turn end, and kept the action's votes.

After the session, the `WORLD_CONGRESS_RESULTS` and `EMERGENCY_DECLARED` notifications came up with popups. Closing them for an agent player is a task of [popups for agent players](../../roadmap/phase-1/agent-popups.md). Confirmed on Windows on 2026-11-11.

## Method

1. Send `Scripts/SentientSystemsCore_WorldCongress.lua`, the choice file, `Scripts/Choices/SentientSystemsCore_Choices.lua`, and `Scripts/Actions/SentientSystemsCore_ActionsWorldCongress.lua` to `SentientSystemsCore_UI`, each without its comments and `include` lines.

   Do so as in [choices/production.md](../choices/production.md#method), step 4.
2. Load a save with `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` up. For a Special Session, see [choices/emergencies.md](../choices/emergencies.md#method).
3. To change the Favor, send `Players[0]:GetDiplomacy():ChangeFavor(amount)` in `GameCore_Tuner`. Call `voteInCongress` from the bridge, wait 3 seconds, and read the blockers and the Favor.

## Results

A single-player game with Gathering Storm, on turn 55, in a Special Session with the player's Betrayal Emergency against player 10 on the floor:

| Call | Result |
| --- | --- |
| `voteInCongress` with 5 votes at 32 Favor | `Cast 1 to 4 votes on WC_EMERGENCY_BACKSTAB with target 10, not 5. Leave a proposal out to abstain.` |
| `voteInCongress` with target 4 | `WC_EMERGENCY_BACKSTAB with target 4 isn't a proposal on the floor. Use one of WC_EMERGENCY_BACKSTAB with target 10.` |
| `voteInCongress` with 55 votes for, at 6,032 Favor | `{"ok":true}`. The blocker cleared, and the Favor went to 92 |
| `SentientSystems_VoteInCongress` with no votes, after that | `There is no World Congress session to vote in. The worldCongress choice lists one while its session is up.` |

On turn 56, `GetEmergencyInfoTable(0)` held the Betrayal Emergency against player 10, begun, with 39 turns left. No emergency blocker was up.

A regular session on turn 85 of another save, at 335 Favor, with Patronage, targeting a great person class, and Trade Policy, targeting a player:

| Call | Result |
| --- | --- |
| `voteInCongress` with Patronage only | `Vote on every resolution. WC_RES_TRADE_TREATY has no vote.` |
| `voteInCongress` with Patronage target 9 of 8 | `Choose a target from 1 to 8 for WC_RES_PATRONAGE, not 9. Use the index of one of its targets.` |
| `voteInCongress` with 13 and 4 votes | `These votes cost 336 Favor, and you have 335.` |
| `voteInCongress` with Patronage A for the Great Scientist, 10 votes, and Trade Policy A for player 0, 5 votes | `{"ok":true}`. The blocker cleared, and the Favor went to 115 |

The voting screen was then closed with **X** and the turn ended. On turn 86, the review held both votes as sent. Patronage went to B, 30 votes to 13, and Trade Policy to A for player 4.

The Favor was 318: 115, 3 a turn, and 200 back for the two choices the congress didn't agree with.

In a first run of the same save, the screen's **Submit** after the action left player 0 with 1 vote on each, as the screen had them, and 118 Favor.

In a third run, with 5 votes on Patronage first and 10 on Trade Policy, the Favor also went from 335 to 115.

Out of session on turn 88 of a third save, at 164 Favor, with the Aid Request for player 0 available at 30 Favor:

| Call | Result |
| --- | --- |
| `proposeInCongress` with target 4 | `WC_EMERGENCY_REQUEST_AID with target 4 isn't a proposal you can make. Use one of WC_EMERGENCY_REQUEST_AID with target 0.` |
| `proposeInCongress` with target 0 | `{"ok":true}`. The Favor went to 134, and the choice listed the proposal as disabled |
| `proposeInCongress` with target 0 again | `You can't propose WC_EMERGENCY_REQUEST_AID with target 0 now. The worldCongress choice lists it as disabled.` |

On turn 89, `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` was up for a Special Session with the Aid Request from player 0 for player 0 on the floor.

The saves were only test saves. In the first, the player's Favor was changed by -1,000 and +6,000 before the vote.

Date checked: game files on 2026-11-11. Running game on Windows on 2026-11-11.
