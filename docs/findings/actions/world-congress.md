# World Congress actions

Status: open. Voting on a Special Session's proposal is confirmed in a running game with Gathering Storm, with the files sent through the tuner. Voting on a regular session's resolutions and making a proposal aren't added yet.

The game calls that the World Congress actions wrap, with the Lua state each runs in and what the game checks. What the player sees in a session is in [choices/world-congress.md](../choices/world-congress.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. What does pressing **Submit** on the voting screen do after the action has voted and submitted?
2. Does the game check a proposal vote's Favor itself, or only the screen?

## What we know now

### Proposal vote

`OnAccept` in `DLC/Expansion2/UI/Additions/WorldCongressPopup.lua` sends one `UI.RequestPlayerOperation(playerID, PlayerOperations.WORLD_CONGRESS_DISCUSSION_VOTE, parameters)` for each proposal on the floor.

The parameters hold the proposal's sender in `PARAM_PLAYER_ONE`, its target in `PARAM_PLAYER_TWO`, and the votes in `PARAM_WORLD_CONGRESS_VOTES`, negative to vote against. The proposal's type isn't sent. Confirmed in files.

It then sends `WORLD_CONGRESS_SUBMIT_TURN` with no parameters, and `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`. Confirmed in files.

### Favor

`GetVotesandFavorCost(playerID)` gives the cost of each number of votes, with the cost of n votes at index n - 1, and `MaxVotes`. Each proposal's votes cost what the list gives for that many, and the screen adds them up against `GetFavor()`. See `OnVoteProposal`. Confirmed in files.

`MaxVotes` follows the player's Favor at the time: the most votes whose cost the Favor covers. It was 23 at 1,032 Favor, 4 at 32, and 55 at 6,032, after `GetDiplomacy():ChangeFavor` in `GameCore_Tuner`. Confirmed on Windows on 2026-11-11.

So one proposal can't cost more than the player has, and the action's cost reason only comes up for votes on several proposals.

### What the request does

In `SentientSystemsCore_UI`, within 3 seconds of the votes and the submit, `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION` was gone and the Favor was down by the votes' cost. The congress was still in session until the turn ended. The submit alone cleared the blocker, without the end turn request.

On the next turn, the Betrayal Emergency had passed and begun, with no blocker. Confirmed on Windows on 2026-11-11.

### Popups

The congress screen opened with **Continue** and then showed the voting screen, though the action had voted. Closing it with **X** let the turn end.

After the session, the `WORLD_CONGRESS_RESULTS` and `EMERGENCY_DECLARED` notifications came up with popups. Closing them for an agent player is a task of [deals and end turn](../../roadmap/phase-1/action-api-deals-and-end-turn.md). Confirmed on Windows on 2026-11-11.

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

The save was only a test save. The player's Favor was changed by -1,000 and +6,000 before the vote.

Date checked: game files on 2026-11-11. Running game on Windows on 2026-11-11.
