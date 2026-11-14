# First meetings

Status: open. The meetings in no man's land, near the AI, and near the player are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

The leader screen sessions an AI opens when it and the player first meet, and how a second meeting waits behind the first. How a session is read and answered is in [ai-sessions.md](ai-sessions.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. Does a first meeting choice change the AI's opinion? After the meetings, Scythia had a +5 and Eleanor a +2 with an unknown reason, and Portugal had none.
2. Does accepting the capital exchange reveal the player's capital to the AI? From `SentientSystemsCore_UI`, `PlayersVisibility[6]:IsRevealed` on the player's capital still returned `false` after the exchange. It may update on the AI's turn, or the UI state may not read another player's visibility.
3. What is the location table in a first meeting statement? Its key, `-1610240504`, has no name from `DiplomacyManager.GetKeyName`.

## What we know now

The tables give `FIRST_MEET_NEAR_INITIATOR` a follow-up with only `CHOICE_EXIT`. They give no follow-up for the others. The game sends one anyway. Confirmed on Windows on 2026-11-13.

| Where they met | First statement | After `POSITIVE` |
| --- | --- | --- |
| The player's unit and the AI's unit, outside both borders | `FIRST_MEET_NO_MANS` | `FIRST_MEET_NO_MANS_INFO_EXCHANGE`, the offer to exchange capital locations |
| The player's unit next to the AI's land | `FIRST_MEET_NEAR_RECIPIENT` | `FIRST_MEET_VISIT_RECIPIENT`, the AI's invitation to its city. Accepting it closed the session |
| The AI's unit next to the player's land | `FIRST_MEET_NEAR_INITIATOR` | Not tried. Its positive option invites the AI to the player's city |

`CloseSession` on the first statement, as its goodbye does, closed the session with no follow-up, and the two players stayed met. Confirmed on Windows on 2026-11-13.

A unit placed with `UnitManager.PlaceUnit` or spawned with `UnitManager.InitUnit` in `GameCore_Tuner` met the civ and opened its session, but the first statement came only after the player asked to end the turn.

The turn didn't end, and the leader screen came up. A placed unit then couldn't move until that request. Confirmed on Windows on 2026-11-13.

The player met Portugal and Scythia with one move of a great merchant. Each opened a `FIRST_MEET_NO_MANS` session. `DiplomacyManager.HasQueuedSession(0)` returned `true`, and Scythia's first statement came only when Portugal's session closed. Confirmed on Windows on 2026-11-13.

1. `AddResponse` with `POSITIVE` on the first statement, the greeting, brought `FIRST_MEET_NO_MANS_INFO_EXCHANGE` in the same session. It is the offer to exchange capital locations.
2. `AddResponse` with `POSITIVE` on the offer revealed Portugal's capital to the player, and the game closed the session itself.
3. `CloseSession` on Scythia's offer, as its decline option does, kept Scythia's capital hidden.

The leader screen showed each statement and closed when each session closed. Confirmed on Windows on 2026-11-13.

A queued session looks open to every call. While Portugal's session was up, `FindOpenSessionID(0, 15)` returned Scythia's session, `GetSessionInfo` gave Scythia as `FromPlayer`, and `IsSessionIDOpen` returned `true` for both. No call tells the two apart. Confirmed on Windows on 2026-11-13.

## Method

1. Add the listeners in step 1 of the [AI sessions method](ai-sessions.md#method).
2. To meet a civ, move a unit until it sees a tile the civ owns. A great merchant with 5 moves reaches far. To have a civ find the player, spawn its unit next to the player's land with `UnitManager.InitUnit(playerID, "UNIT_SCOUT", x, y)` in `GameCore_Tuner`, then end the turn.
3. To answer, send `AddResponse` with the response, or `CloseSession` for `CHOICE_EXIT`. Read the log, `PlayersVisibility[0]:IsRevealed` on the other player's capital, and the sessions section of the state.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| A great merchant moved to `27,31` on turn 391 | `FIRST_MEET_NO_MANS` from Portugal, with Scythia's session queued | 2026-11-13 |
| `AddResponse` with `POSITIVE` on Portugal's greeting, then on the offer | `FIRST_MEET_NO_MANS_INFO_EXCHANGE`, then Portugal's capital revealed and the session closed | 2026-11-13 |
| `AddResponse` with `POSITIVE` on Scythia's greeting, then `CloseSession` | The offer, then the session closed with Scythia's capital still hidden | 2026-11-13 |
| `GetDiplomaticModifiers(0)` for Portugal and Scythia after the meetings | None for Portugal. One +5 with an unknown reason for Scythia | 2026-11-13 |
| A great merchant moved to `27,31` on turn 391, with the sessions section | The state listed Portugal's greeting, then the offer after `POSITIVE`, then Scythia's greeting after `CloseSession`. Scythia was listed as unknown while queued | 2026-11-13 |
| The merchant placed at `23,35`, next to Ambiorix's land, with `PlaceUnit` | Met, and session 11 open with no statement. The state listed it as unknown | 2026-11-13 |
| The player asked to end the turn | `FIRST_MEET_NEAR_RECIPIENT` from Ambiorix, still on turn 391 | 2026-11-13 |
| `AddResponse` with `POSITIVE` twice on Ambiorix's session | `FIRST_MEET_VISIT_RECIPIENT`, then the session closed | 2026-11-13 |
| `InitUnit(18, "UNIT_SCOUT", 49, 27)`, next to the player's land, then an end turn request | Met at once. `FIRST_MEET_NEAR_INITIATOR` from Eleanor came with the request | 2026-11-13 |
| `CloseSession` on Eleanor's first statement | The session closed with no follow-up. Eleanor stayed met, with a +2 modifier with an unknown reason | 2026-11-13 |


Date checked: game files on 2026-11-13. Running game on Windows on 2026-11-13.
