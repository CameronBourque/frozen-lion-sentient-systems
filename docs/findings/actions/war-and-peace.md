# War and peace actions

Status: open. Declaring a surprise war and proposing peace, on a major civ and a city-state, are confirmed in a running game with Gathering Storm, by hand and through the actions, with the files sent through the tuner. How to close the leader screen that a war or a peace leaves open is open.

The game calls that the war and peace actions wrap, with the Lua state they run in. Answering a deal is in [diplomacy.md](diplomacy.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. How can the core mod close the leader screen that a war or a peace leaves open, or keep it from opening for an agent player? No timing of `CloseSession` closes it, and the screen has no event that closes it from outside. See [the leader screen](#the-leader-screen).

## What we know now

### Declaring war

`DeclareWar` in `DeclareWarPopup.lua` sends `DiplomacyManager.RequestSession(attacker, defender, "DECLARE_SURPRISE_WAR")` for a major civ.

For a city-state, it sends `UI.RequestPlayerOperation` with `PlayerOperations.DIPLOMACY_DECLARE_WAR`, and `PARAM_PLAYER_ONE` and `PARAM_PLAYER_TWO` set to the two players.

It tells them apart by `GetCivilizationLevelTypeID`. The formal war and the other casus belli are their own sessions, such as `DECLARE_FORMAL_WAR`. Confirmed in files.

- **The check.** The leader screen tests each option with `player:GetDiplomacy():IsDiplomaticActionValid(actionType, other, true)`, which returns whether it is allowed and a table whose `FailureReasons` are text keys.

  See `DiplomacySupport_RemoveInvalidSelections` in `DiplomacyStatementSupport.lua`. Confirmed in files.

  For `DIPLOACTION_DECLARE_SURPRISE_WAR`, it returned true for every met player at peace, city-states too, and false with no reasons for the 4 players already at war. Confirmed on Windows on 2026-11-11.
- **The session.** For a major civ, the session was open at once, and its `FromPlayer` was the player. Confirmed on Windows on 2026-11-11.

  With no other session open, closing the session right after the request kept the war. With another player's session open, the war session waited behind it, and closing it at once cancelled the war. Confirmed on Windows on 2026-11-11.
- **Other players' sessions.** After a war on player 4, and again after a war on city-state 12, Scythia opened a session of their own to comment, as their agenda reacts to the war. It held no deal. Confirmed on Windows on 2026-11-11 and 2026-11-12.
- **City-states.** The war on a city-state wasn't in place right after the call, and was a moment later. Confirmed on Windows on 2026-11-12.

`SentientSystems_DeclareWar` declared war on city-state 12 with no session, and on players 4 and 7 with the session closed at once. A second call for each returned the reason for a player already at war. Confirmed on Windows on 2026-11-11.

### Proposing peace

The leader screen's **Make Peace**, in `OnSelectInitialDiplomacyStatement` in `DiplomacyActionView.lua`, clears the outgoing deal and adds an agreement item from the player with the sub type `DealAgreementTypes.MAKE_PEACE`, locked.

It validates the deal and asks for a `MAKE_DEAL` session, and the deal screen's **Propose** sends the deal as `DealProposalAction.PROPOSED`. Confirmed in files.

For a city-state, `OnChangeWarPeaceStatus` in `CityStates.lua` sends `UI.RequestPlayerOperation` with `PlayerOperations.DIPLOMACY_MAKE_PEACE` and the two players.

The screen enables the button with `CanMakePeaceWith`, and its tooltip names a suzerain at war with the player or the turns left. Confirmed in files.

- **The check.** `IsDiplomaticActionValid` with `DIPLOACTION_MAKE_PEACE` gave "Unable to Make Peace[NEWLINE]You must wait 8 turns after declaring war (available in 8 turns)." for a war declared that turn. It gave true for Vietnam, at war for more than 10 turns.

  It gave true for a city-state at peace too, so a city-state uses `CanMakePeaceWith`. Confirmed on Windows on 2026-11-12.
- **The deal.** Validating the deal added peace from the other side, and a city item from Vietnam with sub type 1 for Con Cuông, a Vietnamese city the player occupied, named "Con Cuông, cede." Confirmed on Windows on 2026-11-12.
- **The answer.** Vietnam answered with an `AI_ACCEPT_DEAL` statement, and peace took effect with Vietnam and with the city-states on both sides. No second `ACCEPTED` was needed. It came after the call that proposed it, and within 1 s. Confirmed on Windows on 2026-11-12.
- **The session.** With no other session open, closing the session in the call that proposed peace kept the peace. The leader screen stayed on the overview, as after a war. Confirmed on Windows on 2026-11-12.

`SentientSystems_ProposePeace`, with the bridge's wait, made peace with Vietnam in 584 ms. Con Cuông stayed the player's, no longer occupied. A city-state at war for less than a turn returned the city-state reason. Confirmed on Windows on 2026-11-12.

### The leader screen

A war request plays the leader screen through: the other leader's reply, the leader scene, the reaction animation, and the goodbye. In `SentientSystemsCore_UI`, the reply statement and `Events.LeaderScreenFinishedLoading` came within a second of the request.

`Events.LeaderAnimationComplete` with `DECLARE_WAR_FROM_HUMAN` came 7 s to 9 s after it. Confirmed on Windows on 2026-11-12.

`OnDiplomacySessionClosed` in `DiplomacyActionView.lua` returns the screen to the overview of the other leader when the player started the session, and closes it only when the other player did. Before the screen is set up, it ignores the close. Confirmed in files.

No timing of `CloseSession` closed the screen. Closed at once, on the reply, or on the leader load, the screen ended on the overview. Closed on the animation, it ended on the goodbye. Confirmed on Windows on 2026-11-12.

The screen closes itself with `OnForceClose` when the local player's turn ends or begins, and when the wonder or natural wonder popup signals it opened. `InGame.lua` hides the whole HUD on those same popup signals. Confirmed in files.

## Method

1. To run the actions before the `.modinfo` loads them, send `SentientSystemsCore_ActionsDeals.lua` without its comment and include lines.
2. To declare war, call `declareWar` for a city-state and a major civ at peace, then again for each. Read `IsAtWarWith` and `FindOpenSessionID` for each player.
3. To test the session close, send `RequestSession` with `DECLARE_SURPRISE_WAR` and `CloseSession` in one call, with and without another session open, and read `IsAtWarWith` 3 s later.
4. To propose peace, read each occupied city's owner, call `proposePeace` for a major civ at war for more than 10 turns, and read them again. Call it for a major civ and a city-state at war for less.
5. To time the leader screen, add listeners in `SentientSystemsCore_UI` to `Events.DiplomacyStatement`, `Events.LeaderScreenFinishedLoading`, `Events.LeaderAnimationComplete`, and `Events.DiplomacySessionClosed` that log `os.clock()`. Close the war session from one of them, and look at the screen.

## Results

A single-player game with Gathering Storm, on turn 54, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| `declareWar(client, 0, 12)` on a city-state, then again | At war within 3 s, with no session. The second call returned the already-at-war reason | 2026-11-11 |
| `declareWar(client, 0, 4)` before the action closed the session | At war, with the session open 3 s later and the Maori leader's reply on screen. Closing it closed the screen and kept the war. Scythia then opened a session to comment | 2026-11-11 |
| `RequestSession` and `CloseSession` in one call for player 6, with Scythia's session open | Not at war 3 s later | 2026-11-11 |
| The same for player 6, after closing Scythia's session | At war 3 s later, with no session open | 2026-11-11 |
| `declareWar(client, 0, 7)`, which closes the session itself, then again | At war, with no session open, and the leader screen on the overview. The second call returned the already-at-war reason | 2026-11-11 |
| A war on player 8, with the session closed by a listener on the reply statement | At war, and the leader screen on the overview | 2026-11-12 |
| A war on player 9, with the session closed on `LeaderScreenFinishedLoading` | At war, and the leader screen on the overview | 2026-11-12 |
| A war on player 11, with the session closed on `LeaderAnimationComplete`, 9 s after the request | At war. The animation played, and the leader screen ended on the goodbye | 2026-11-12 |
| The peace deal, the `MAKE_DEAL` session, and `PROPOSED` to Vietnam by hand | `AI_ACCEPT_DEAL` within 1 s, and peace. The leader screen stayed on the overview | 2026-11-12 |
| The same, with `CloseSession` in the same call | Still at war right after the call, and at peace 3 s later | 2026-11-12 |
| `proposePeace(client, 0, 10)` after a reload, then again | `{"ok":true}` in 584 ms, and Con Cuông the player's, no longer occupied. The second call returned the not-at-war reason | 2026-11-12 |
| `proposePeace` to city-state 12, just after `declareWar` on it | The city-state reason | 2026-11-12 |

Date checked: game files on 2026-11-11 and 2026-11-12. Running game on Windows: the war action on 2026-11-11, and the leader screen and peace on 2026-11-12.
