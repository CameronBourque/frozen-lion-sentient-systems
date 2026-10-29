# Game diplomacy

Status: open. The `diplomacy` section of `SentientSystems_GetState`, the status of each met player, is confirmed in a running game with Gathering Storm, with the file sent through the tuner. It matches the Intel Report for one player, at war with another, and for a declared friendship and an alliance set with the tuner. A denouncement is checked in the fake game only. The `proposals` section, the deals other players put to the player, is confirmed against a pending proposal with gold, resources, an agreement, and a city with its great works and resources, and against an alliance with a third-party war that the player proposed. A research agreement item isn't confirmed. The relationship reasons, agendas, grievances, and the other players' relationships are confirmed on a save at turn 26 with Gathering Storm, and the promises are left out.

The calls the diplomacy status and the proposals use, as the Intel Report in `DiplomacyActionView.lua` and the deal screen in `DiplomacyDealView.lua` show them. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the denounce countdown match the Intel Report's tooltip in a running game?
2. Does a research agreement item give its `tech` through `GameInfo.Technologies`, as the screen's agreement options have it?
3. Can an AI demand be told from a proposal? The session info only has `FromPlayer` and `ToPlayer`, and the screen sets its demand flag from the statement that opens it.
4. Which relationships does the Overview's last row hide? It skips a state with `Relationship.IsValidWithAI`, a global that the core mod's state doesn't have, so the state leaves out only the neutral ones and may show some that the screen hides.
5. Does a promise to keep troops away from a player show in `IsPromiseMade`? After the player told Australia their troops were passing by, and a turn was played, it was false for every player and promise type, and the game has the type `KEEP_TROOPS_AWAY_FROM_ME`, which no screen lists. The state leaves promises out.
6. Is `state` left out for a player that is an agent? Agents don't exist yet, so the core mod leaves it out for a human only. When agents come, the check must leave it out for them too, as their relationship is not a calculated one.

## What we know now

### Intel report

`DiplomacyActionView.lua` draws the Overview tab, and the Rise and Fall and Gathering Storm replacements and additions add the alliance tab. Confirmed in files.

- **State.** `GetDiplomaticAI():GetDiplomaticStateIndex(playerID)` of the other player is what they think of the player, which the Overview shows as **Our Relationship**: `DIPLO_STATE_FRIENDLY` for Menelik. The screen hides it for a human, as `IsHuman()` is true for their configuration. War is `IsAtWarWith` and the state `DIPLO_STATE_WAR`, which the save had with Vietnam. Confirmed in files and on Windows on 2026-10-29.
- **Access and government.** `GetVisibilityOn(playerID)` indexes `GameInfo.Visibilities`, which was 1, **Limited**, for most players and 2, **Open**, for some. The government is `GetCulture():GetCurrentGovernment()`, with the turns of anarchy left from `GetAnarchyEndTurn()`. Confirmed in files and on Windows on 2026-10-29.
- **Agreements.** The Overview's icons come from `HasDelegationAt`, `HasEmbassyAt`, `HasDefensivePact`, `HasOpenBordersFrom` from each side, `GetResearchAgreementTech`, and `IsFightingAnyJointWarWith`. Menelik had received open borders, the one icon, and had a delegation at the player's cities. Confirmed in files and on Windows on 2026-10-29.
- **Turns left.** A declared friendship ends `GetDeclaredFriendshipTurn` plus `GetGameDiplomacy():GetDenounceTimeLimit()`, 20, after the turn it was declared, which was 20 on the turn it was set. A denouncement counts from the later of the two denounce turns, with a turn added by the tooltip's order rule, which gave 11 on turn 85 for a denouncement on turn 74 by the player with the higher ID. Confirmed in files, and the declared friendship on Windows on 2026-10-29.
- **Alliance.** With Rise and Fall, `GetAllianceLevel` is 1 or more for every player, with `GetAllianceTurnsThisLevel` and `GetAllianceTurnsToNextLevel` in turns that the screen divides by `GlobalParameters.ALLIANCE_POINTS_MULTIPLIER`, 4, so 0 of 40 points at level 1 and 34 of 80 at level 2. `GetAllianceType` is -1 without an alliance. At level 3 the screen shows MAX. An alliance made with the tuner gave `ALLIANCE_RESEARCH`, 1.25 points per turn, and 20 turns until it expires. Confirmed in files and on Windows on 2026-10-29.

### Deal screen

`DiplomacyDealView.lua`, and the Gathering Storm copy in `DLC/Expansion2/UI/Replacements`, draw the deal. When an AI proposes one, `DiplomacyManager.FindOpenSessionID(player, other)` is an open session, whose `GetSessionInfo` has `FromPlayer` and `ToPlayer`, and the proposal is `DealManager.GetWorkingDeal(DealDirection.INCOMING, player, other)`. The screen copies it to the outgoing working deal, for the player to change. Confirmed in files.

- **Items.** `Items()` lists each item, with `GetID`, `GetType`, one of the `DealItemTypes`, `GetSubType`, `GetFromPlayerID`, `GetAmount`, `GetDuration`, which is 0 for an item that happens once, `GetValueType`, `GetValueTypeNameID`, `IsUnacceptable`, and `IsLocked`. A deal has `IsGift`, `Validate`, `IsValid`, and `GetItemParent(item)`. Kupe's proposal had 10 Horses from the player, and 8 gold, 3 gold for 30 turns, and Open Borders for 20 turns from Kupe. Confirmed on Windows on 2026-10-30.
- **Types.** `DealItemTypes` has gold, resources, agreements, cities, great works, captives, units, technology, and favor. An agreement's sub type is a hash in `DealAgreementTypes`, which `GameInfo.DiplomaticActions` finds by hash: Open Borders, Alliance, Research Agreement, Joint War, Third Party War, and Make Peace. The screen takes an agreement's value as a tech for a research agreement, an alliance type, or the player a war is against, with the war type as the parameter `WarType`. Confirmed in files, and the Open Borders hash on Windows on 2026-10-30.
- **Alliance and war items.** An alliance is two items, one from each player, both locked, with sub type `DealAgreementTypes.ALLIANCE` and as value the hash of the alliance type, `LOC_ALLIANCE_MILITARY` here, which `GameInfo.Alliances` finds. **Join Ongoing War** is `THIRD_PARTY_WAR`, 20 turns, with the war's target player as value, 10 for Vietnam, and `GetParameterValue("WarType")`, a hash that `GameInfo.Wars` finds as `FORMAL_WAR`. It was marked unacceptable, as the screen's red mark showed. A joint war is read the same way and wasn't seen. Confirmed on Windows on 2026-10-30.
- **Cities.** A city item's value is the city's ID, and its sub type is 1 for a city ceded back after an occupation, and 2 here. The resources and great works that come with a city are locked items whose parent is the city's item. Bagacum came with 2 Niter, 1 Honey, and two great works. Confirmed on Windows on 2026-10-30.

### Relationships, agendas, and grievances

The Relationship tab lists `GetDiplomaticAI():GetDiplomaticModifiers(player)` of the other player, each with `Score` and `Text`, sorted by score, and skips 0. The text is already in the player's language, and the one the screen greys out for a reason it can't explain, which was "Unknown Reason" here, is `unknown` in the state. The Overview's agendas are `GetAgendaTypes()` of the other player, whose first is the historical agenda. The rest show when a `GameInfo.Visibilities` row at or below the access level has `RevealAgendas`, which only **Open** has, and otherwise as a count. The Grievances tab, with Gathering Storm, has `GetGrievancesAgainst(other)`, positive when the player has grievances against them, `Game.GetGameDiplomacy():GetGrievanceChangePerTurn`, and `GetGrievanceLogEntries(other, player)`, each with `Turn`, `Initiator`, `Target`, `Amount`, and `Description`. The Overview's Relationships row is how each other player the selected player has met sees them. Confirmed in files and on Windows on 2026-10-30.

- **On the saves.** Menelik's reasons were +9, +2, and an unknown +6, with one agenda shown and one hidden at **Limited** access. Vietnam had 55 grievances in a log of 6 entries, such as `War Declared on City-State: Hong Kong`. On the turn 26 save, 10 met players had their agendas and reasons, and 6 had other relationships. Confirmed on Windows on 2026-10-30.

## Method

1. To read the section before the `.modinfo` loads `SentientSystemsCore_StateDiplomacy.lua`, send the file without its comment lines, then `print(SentientSystems_EncodeJson(SentientSystems_GetDiplomacyState(Players[0])))`, as in [game-choices.md](game-choices.md#method), step 6.
2. To set a status without playing it, send in `GameCore_Tuner` `Players[0]:GetDiplomacy():SetHasDeclaredFriendship(2, true)` and the same on player 2 for 0, or `SetHasAllied`. Reload the save to undo it.
3. Compare with the Intel Report of the player, in the diplomacy screen.
4. For the proposals, end the turn so that an AI proposes a deal, then send `SentientSystemsCore_StateProposals.lua` without its comment lines, and `print(SentientSystems_EncodeJson(SentientSystems_GetProposalState(Players[0])))`. Compare with the deal screen.

## Results

A single-player game with Gathering Storm, on turns 73 and 85, with 11 other players, all met:

| Check | Result |
| --- | --- |
| Menelik's status against the Intel Report | Friendly, **Limited** access, Autocracy, one agreement icon, and alliance level 1 at 0 of 40, as the screens showed |
| A save at war with Vietnam | `atWar` true and the state `DIPLO_STATE_WAR`, as the player's leader icon showed |
| A declared friendship and an alliance set with the tuner | `DIPLO_STATE_DECLARED_FRIEND` with 20 turns left, and `DIPLO_STATE_ALLIED` with `ALLIANCE_RESEARCH`, a defensive pact, and open borders both ways |
| The section through the bridge's reader | `DIPLOMACY` parsed 11 players |
| An alliance and a third-party war that the player proposed to Qin, read with the session check off | `ALLIANCE_MILITARY` from both sides and `THIRD_PARTY_WAR` against player 10, `FORMAL_WAR`, unacceptable, as the deal screen showed. The state leaves it out, as the player started the session |
| The relationships, agendas, grievances, and others on a turn 26 save, through the bridge's reader | `DIPLOMACY` parsed 10 players, with each agenda and reason, and Gandhi's "pleased that you have been keeping the peace" at +5. The promise to Australia wasn't in the data |
| A pending proposal from Kupe, with a city added | `PROPOSALS` parsed 1 proposal with 6 asks and 3 offers: the Horses, Bagacum with its 2 Niter, 1 Honey, and 2 great works, and from Kupe the Open Borders and the two gold items, as the deal screen showed |

Date checked: game files and a running game on Windows on 2026-10-29 and 2026-10-30.
