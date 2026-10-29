# Game diplomacy

Status: open. The `diplomacy` section of `SentientSystems_GetState`, the status of each met player, is confirmed in a running game with Gathering Storm, with the file sent through the tuner. It matches the Intel Report for one player, at war with another, and for a declared friendship and an alliance set with the tuner. A denouncement is checked in the fake game only. Proposed deals and the relationships, grievances, and agendas parts aren't done.

The calls the diplomacy status uses, as the Intel Report in `DiplomacyActionView.lua` shows them. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the denounce countdown match the Intel Report's tooltip in a running game?
2. Is `state` left out for a player that is an agent? Agents don't exist yet, so the core mod leaves it out for a human only. When agents come, the check must leave it out for them too, as their relationship is not a calculated one.

## What we know now

### Intel report

`DiplomacyActionView.lua` draws the Overview tab, and the Rise and Fall and Gathering Storm replacements and additions add the alliance tab. Confirmed in files.

- **State.** `GetDiplomaticAI():GetDiplomaticStateIndex(playerID)` of the other player is what they think of the player, which the Overview shows as **Our Relationship**: `DIPLO_STATE_FRIENDLY` for Menelik. The screen hides it for a human, as `IsHuman()` is true for their configuration. War is `IsAtWarWith` and the state `DIPLO_STATE_WAR`, which the save had with Vietnam. Confirmed in files and on Windows on 2026-10-29.
- **Access and government.** `GetVisibilityOn(playerID)` indexes `GameInfo.Visibilities`, which was 1, **Limited**, for most players and 2, **Open**, for some. The government is `GetCulture():GetCurrentGovernment()`, with the turns of anarchy left from `GetAnarchyEndTurn()`. Confirmed in files and on Windows on 2026-10-29.
- **Agreements.** The Overview's icons come from `HasDelegationAt`, `HasEmbassyAt`, `HasDefensivePact`, `HasOpenBordersFrom` from each side, `GetResearchAgreementTech`, and `IsFightingAnyJointWarWith`. Menelik had received open borders, the one icon, and had a delegation at the player's cities. Confirmed in files and on Windows on 2026-10-29.
- **Turns left.** A declared friendship ends `GetDeclaredFriendshipTurn` plus `GetGameDiplomacy():GetDenounceTimeLimit()`, 20, after the turn it was declared, which was 20 on the turn it was set. A denouncement counts from the later of the two denounce turns, with a turn added by the tooltip's order rule, which gave 11 on turn 85 for a denouncement on turn 74 by the player with the higher ID. Confirmed in files, and the declared friendship on Windows on 2026-10-29.
- **Alliance.** With Rise and Fall, `GetAllianceLevel` is 1 or more for every player, with `GetAllianceTurnsThisLevel` and `GetAllianceTurnsToNextLevel` in turns that the screen divides by `GlobalParameters.ALLIANCE_POINTS_MULTIPLIER`, 4, so 0 of 40 points at level 1 and 34 of 80 at level 2. `GetAllianceType` is -1 without an alliance. At level 3 the screen shows MAX. An alliance made with the tuner gave `ALLIANCE_RESEARCH`, 1.25 points per turn, and 20 turns until it expires. Confirmed in files and on Windows on 2026-10-29.

## Method

1. To read the section before the `.modinfo` loads `SentientSystemsCore_StateDiplomacy.lua`, send the file without its comment lines, then `print(SentientSystems_EncodeJson(SentientSystems_GetDiplomacyState(Players[0])))`, as in [game-choices.md](game-choices.md#method), step 6.
2. To set a status without playing it, send in `GameCore_Tuner` `Players[0]:GetDiplomacy():SetHasDeclaredFriendship(2, true)` and the same on player 2 for 0, or `SetHasAllied`. Reload the save to undo it.
3. Compare with the Intel Report of the player, in the diplomacy screen.

## Results

A single-player game with Gathering Storm, on turns 73 and 85, with 11 other players, all met:

| Check | Result |
| --- | --- |
| Menelik's status against the Intel Report | Friendly, **Limited** access, Autocracy, one agreement icon, and alliance level 1 at 0 of 40, as the screens showed |
| A save at war with Vietnam | `atWar` true and the state `DIPLO_STATE_WAR`, as the player's leader icon showed |
| A declared friendship and an alliance set with the tuner | `DIPLO_STATE_DECLARED_FRIEND` with 20 turns left, and `DIPLO_STATE_ALLIED` with `ALLIANCE_RESEARCH`, a defensive pact, and open borders both ways |
| The section through the bridge's reader | `DIPLOMACY` parsed 11 players |

Date checked: game files and a running game on Windows on 2026-10-29.
