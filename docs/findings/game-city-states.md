# Game city-states

Status: open. The `envoys` key of `SentientSystems_GetChoices`, the city-states the player can send envoys to, and the `envoys` section of `SentientSystems_GetState`, the player's envoy tokens and each met city-state's envoys and suzerain, are confirmed in a running game with Gathering Storm, with the files sent through the tuner, and match the City-States screen.

The calls the envoy choice and the envoys section of the state use, as the City-States screen shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### City-States screen

`Base/Assets/UI/PartialScreens/CityStates.lua` draws the City-States screen. Rise and Fall and Gathering Storm replace it with `CityStates_Expansion1.lua` and `CityStates_Expansion2.lua`, which add each city-state's governors and change the suzerain bonus text, and leave the envoys and suzerain as they are. Confirmed in files.

- **City-states.** `GetData`, lines 1411 to 1530, lists each player from `PlayerManager.GetAliveMinors()` other than the player for which `GetInfluence():CanReceiveInfluence()` is `true`, and the list shows those the player has met. The Free Cities, player 62, are a minor player for which `CanReceiveInfluence()` is `false`. The name is `Locale.Lookup` of `PlayerConfigurations[id]:GetCivilizationShortDescription()`, such as Bandar Brunei for `CIVILIZATION_JAKARTA`. Confirmed in files and on Windows on 2026-10-26.
- **Kind.** `GetCityStateType`, lines 1591 to 1613, reads the kind from the leader in `PlayerConfigurations[id]:GetLeaderTypeName()`, or the leader its `GameInfo.Leaders` row names in `InheritFrom`, such as `LEADER_MINOR_CIV_TRADE` for `LEADER_MINOR_CIV_SAMARKAND`. The screen's own name for the cultural kind is `CULTURE`, and the state uses the leader's `CULTURAL`. Confirmed in files and on Windows on 2026-10-26.
- **Envoys and suzerain.** On the city-state's `GetInfluence()`, `GetTokensReceived(playerID)` is that player's envoys, `GetMostTokensReceived()` the most of any player, and `GetSuzerain()` the suzerain's ID, or -1 for none. The screen names the suzerain as **You**, a met player's leader, such as Poundmaker for the Cree, or **Unmet Player** for a player the player hasn't met. The envoys to be suzerain are the most of any player plus one, or the most when the player is suzerain, and at least 3, a number the file sets by hand. Confirmed in files and on Windows on 2026-10-26.
- **Tokens and influence.** On the player's `GetInfluence()`, `GetTokensToGive()` is the envoys to send, and `GetPointsEarned()`, `GetPointsPerTurn()`, `GetPointsThreshold()`, and `GetTokensPerThreshold()` are the influence the header's meter and tooltip show, in `RealizeListHeader`, lines 609 to 662. Confirmed in files and on Windows on 2026-10-26.
- **Sending.** The screen opens in send mode when the player has tokens and has met a city-state. `RealizeEnvoyChangeButtons`, lines 667 to 701, turns on a city-state's buttons when the player's `CanGiveTokensToPlayer(id)` is `true`. It was `true` for each met city-state, and `false` for one at war with the player, an unmet one, and the Free Cities. `OnConfirmPlacement`, lines 748 to 772, sends `PlayerOperations.GIVE_INFLUENCE_TOKEN` once for each envoy, with the city-state's ID in `PARAM_PLAYER_ONE`. Confirmed in files and on Windows on 2026-10-26.
- **Blocker.** `Close`, lines 441 to 457, calls the player's `SetGivingTokensConsidered(true)`, and `IsGivingTokensConsidered()` then stays `true` with tokens left. `ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN` was among the blockers while it was `false`, and was gone once it was `true`, with 4 tokens left. Confirmed in files and on Windows on 2026-10-26.
- **War.** After the player went to war with a city-state, their envoys there were 0, and `CanGiveTokensToPlayer` was `false`. The state still lists the city-state, as the screen does, with a war icon. Confirmed on Windows on 2026-10-26.
- **Left out.** The state leaves out each city-state's bonuses for 1, 3, and 6 envoys and its suzerain bonus, its quests, the other players' envoys that the **Influenced By** tab lists, and the governors the expansions add. Confirmed in files.

## Method

1. To read a choice or a state section that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6. The full state and choices need `SentientSystemsCore_State.lua` and `SentientSystemsCore_Choices.lua` sent again too, so they call the new file.
2. To meet a city-state, send `Players[0]:GetDiplomacy():SetHasMet(id)` in `GameCore_Tuner`. Meeting one first gave the player 1 envoy there.
3. To give envoys, send `Players[0]:GetInfluence():ChangeTokensToGive(n)` in `GameCore_Tuner`. `GiveFreeTokenToPlayer(id)` on a player's influence gives that player an envoy at the city-state, and does nothing until the player has met it.
4. To go to war with a city-state, send `Players[0]:GetDiplomacy():DeclareWarOn(id, WarTypes.FORMAL_WAR, true)` in `GameCore_Tuner`. `DeclareWarOn(id)` alone did nothing.

## Results

A single-player game with Gathering Storm, on turn 1 of a save with 18 city-states, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The influence before any change | 0 tokens, 0 points, 0 per turn, 1 envoy for each 50 points. Each of the 18 city-states unmet, with no suzerain |
| The state after meeting four city-states and the Cree, adding 4 tokens, giving Granada 3 more envoys, the Cree 3 at Samarkand, and China 3 at Cahokia | Samarkand, a trade city-state, with 2 envoys, the Cree as suzerain, and 4 to be suzerain. Cahokia, trade, 1 envoy, an unmet suzerain, 4. Granada, militaristic, 4 envoys, the player as suzerain, 4. Caguana, cultural, 1 envoy, no suzerain, 3. 4 tokens. The Free Cities, met and at war, left out |
| The choices with the same envoys | `{"cityStates":[12,13,14,15],"tokens":4}` |
| The choices after going to war with Caguana | `{"cityStates":[12,13,14],"tokens":4}`, and Caguana with 0 envoys in the state |
| The state and choices through the bridge's readers | Both parsed, with the same values |
| The City-States screen after the war | **Send envoys (4)** and 1 envoy at 50 influence points. Samarkand with 2 envoys, suzerain Poundmaker, 4 to be suzerain. Cahokia with 1, suzerain Unmet Player, 4. Granada with 4, suzerain You, 4. Caguana with 0, suzerain None, 3, and a war icon. The same as the state |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
