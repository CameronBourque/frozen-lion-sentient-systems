# AI diplomacy sessions

Status: open. Comments, the first meeting in no man's land, and how an open session holds the turns are confirmed in a running game with Gathering Storm, with calls sent through the tuner. The requests and the other first meetings are confirmed in files only.

The game calls that read and answer a session an AI opens with no deal, such as a comment, a request, or a first meeting, with the Lua state they run in. Sessions that hold a deal are in [diplomacy.md](diplomacy.md). Declaring war and proposing peace are in [war-and-peace.md](war-and-peace.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. What do the requests do when answered? The requests are a delegation, an embassy, open borders, friendship, an alliance, and the promises. Record the follow-up statement for each response, and whether the game closes the session after it.
2. What are the statements of the first meetings near the recipient, a visit to the recipient, and near the initiator? Record what `CHOICE_EXIT` on the first statement does.
3. Does a first meeting choice change the AI's opinion? After the meeting in no man's land, neither leader listed a modifier from it.
4. Does accepting the capital exchange reveal the player's capital to the AI? From `SentientSystemsCore_UI`, `PlayersVisibility[6]:IsRevealed` on the player's capital still returned `false` after the exchange. It may update on the AI's turn, or the UI state may not read another player's visibility.
5. What is the location table in a first meeting statement? Its key, `-1610240504`, has no name from `DiplomacyManager.GetKeyName`.

## What we know now

### What a session holds

A session is a series of statements between two players under one session ID. Each statement has a type, such as `DIPLOMATIC_WARNING`, and a subtype, such as `NONE` or `POSITIVE`. Confirmed on Windows on 2026-11-13.

`DiplomacyManager.GetSessionInfo(sessionID)` returns only `FromPlayer` and `ToPlayer`. `DiplomacyManager.FindOpenSessionID(player, other)` finds the open session. No call returns the statement. Confirmed on Windows on 2026-11-13.

`Events.DiplomacyStatement(fromPlayer, toPlayer, kVariants)` sends each statement. `kVariants` holds these fields:

- `SessionID` and `SessionStatementIndex`.
- `StatementType` and `StatementSubType`, as hashes that `DiplomacyManager.GetKeyName` turns into names.
- `FromPlayer`, `ToPlayer`, and `Initiator`. For a session the AI opens, `Initiator` is the AI.
- `AiReason` and `AiModifier`. In Scythia's comment, `AiModifier` was the hash of `AGENDA_BACKSTAB_AVERSE_SURPRISE_WAR`.
- `ResponseType`, which is the hash of `INITIAL` on the statement that opens a session.

A first meeting statement also holds a table under the key `-1610240504`, with `x` and `y`. Both were `-9999` in the meeting in no man's land. Confirmed on Windows on 2026-11-13.

`OnDiplomacyStatement` in `DiplomacyActionView.lua` opens the leader screen from the first statement of a session. The screen shows each later statement of that session. Confirmed in files.

### The options

`DiplomacySupport_ExtractStatement` in `DiplomacyStatementSupport.lua` reads a statement's text and its options from the `DiplomacyStatements` and `DiplomacySelections` tables.

It matches the type, the subtype, the initiator, the leader, and the mood, and falls back to `ANY` for the leader and the mood.

`DiplomacySupport_RemoveInvalidSelections` then removes an option whose `DiplomaticActionType` fails `IsDiplomaticActionValid`. Confirmed in files.

`OnSelectConversationDiplomacyStatement` in `DiplomacyActionView.lua` sends each option key as follows. The Expansion 1 replacement adds only war keys. Confirmed in files.

| Key | Call |
| --- | --- |
| `CHOICE_POSITIVE` | `DiplomacyManager.AddResponse(sessionID, player, "POSITIVE")` |
| `CHOICE_NEGATIVE` | `AddResponse` with `"NEGATIVE"` |
| `CHOICE_IGNORE` | `AddResponse` with `"RESPONSE_IGNORE"` |
| `CHOICE_STOP_ASKING` | `AddResponse` with `"REJECTED_PERMANENT"`, after a confirm popup. Only for an AI |
| `CHOICE_EXIT` | `ExitConversationMode`, which calls `DiplomacyManager.CloseSession(sessionID)` |
| Any other key | `AddResponse` with the key |

A response leads to the AI's next statement in the same session. Its subtype names the answer, such as `POSITIVE` or `HUMAN_REFUSE_DEAL`. Confirmed in files.

The AI statements fall into these groups, with the options the tables give for `ANY` leader and mood. Confirmed on Windows on 2026-11-13, from `GameInfo` in the running game.

| Statements | First options | Follow-up options |
| --- | --- | --- |
| Kudos, warnings, their `HIDDEN_AGENDA` forms, `DENOUNCE`, `DEFEAT`, and every war declaration | `CHOICE_EXIT` | None |
| `DIPLOMATIC_DELEGATION`, `RESIDENT_EMBASSY`, `OPEN_BORDERS`, `MAKE_ALLIANCE`, `RENEW_ALLIANCE`, and `MAKE_PEACE` | Positive, negative, and exit | `CHOICE_EXIT` |
| `DECLARE_FRIEND` | `CHOICE_POSITIVE`, `CHOICE_NEGATIVE`, `CHOICE_STOP_ASKING`, and `CHOICE_EXIT` | `CHOICE_EXIT` |
| The promises, such as `WARNING_DONT_SETTLE_NEAR_ME` and `WARNING_STOP_SPYING_ON_ME` | `CHOICE_POSITIVE` and `CHOICE_NEGATIVE` | `CHOICE_EXIT` |
| The five `FIRST_MEET` statements: `NEAR_RECIPIENT`, `VISIT_RECIPIENT`, `NEAR_INITIATOR`, `NO_MANS`, and `NO_MANS_INFO_EXCHANGE` | `CHOICE_POSITIVE` and `CHOICE_EXIT` | See [first meetings](#first-meetings) |

A promise has no `CHOICE_EXIT` until it is answered. For most promises, the text of `CHOICE_POSITIVE` gives 30 Diplomatic Favor, and the text of `CHOICE_NEGATIVE` gives 25 Grievances.

For `WARNING_TOO_MANY_TROOPS_NEAR_ME`, `CHOICE_NEGATIVE` declares war. Confirmed on Windows on 2026-11-13, from `Locale.Lookup` of the option text.

### Comments

After a war on the Maori, Scythia opened a `DIPLOMATIC_WARNING` session. Its only option was `CHOICE_EXIT`. Later wars on the Cree and the Netherlands in the same turn brought no comment. Confirmed on Windows on 2026-11-13.

During the AI turns, Persia opened a `DIPLOMATIC_KUDO` session. The AI turns stopped until `CloseSession` closed it. Kongo then proposed a deal, and the turn went on after `SentientSystems_RespondToDeal` rejected it. Confirmed on Windows on 2026-11-13.

### First meetings

The tables give `FIRST_MEET_NEAR_INITIATOR` a follow-up with only `CHOICE_EXIT`. They give no follow-up for the others. In the game, a positive answer to `FIRST_MEET_NO_MANS` brought `FIRST_MEET_NO_MANS_INFO_EXCHANGE` as the next statement. Confirmed on Windows on 2026-11-13.

The player met Portugal and Scythia with one move of a great merchant. Each opened a `FIRST_MEET_NO_MANS` session. `DiplomacyManager.HasQueuedSession(0)` returned `true`, and Scythia's first statement came only when Portugal's session closed. Confirmed on Windows on 2026-11-13.

1. `AddResponse` with `POSITIVE` on the first statement, the greeting, brought `FIRST_MEET_NO_MANS_INFO_EXCHANGE` in the same session. It is the offer to exchange capital locations.
2. `AddResponse` with `POSITIVE` on the offer revealed Portugal's capital to the player, and the game closed the session itself.
3. `CloseSession` on Scythia's offer, as its decline option does, kept Scythia's capital hidden.

The leader screen showed each statement and closed when each session closed. Confirmed on Windows on 2026-11-13.

### What an open session stops

A session waits behind another open session, and a war request then fails. See [declaring war](war-and-peace.md#declaring-war).

An end turn request with a leader screen up closes the screen and doesn't end the turn. See [ending the turn](end-turn.md#ending-the-turn).

## Method

1. Add a listener to `Events.DiplomacyStatement` in `SentientSystemsCore_UI` that logs `os.clock()`, each field of `kVariants`, and `DiplomacyManager.GetKeyName` of each number. Add one to `Events.DiplomacySessionClosed`.
2. To get a comment, declare war on a major civ with `SentientSystems_DeclareWar`, or end the turn. Read the log and `DiplomacyManager.GetSessionInfo` of each session from `FindOpenSessionID`.
3. To list the options, read `GameInfo.DiplomacyStatements` and `GameInfo.DiplomacySelections` for the rows with `ANY` leader and mood, and the `Locale.Lookup` of each option's text.
4. To answer, send `AddResponse` with the response, or `CloseSession` for `CHOICE_EXIT`. Read the log, the turn, and `PlayersVisibility[0]:IsRevealed` on the other player's capital.
5. To meet a civ, move a unit until it sees a tile the civ owns.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| `SentientSystems_DeclareWar(0, 4)` on turn 85 | Scythia's `DIPLOMATIC_WARNING` session opened, with only `CHOICE_EXIT` | 2026-11-13 |
| `SentientSystems_DeclareWar(0, 1)`, then `(0, 7)` | No comment from any player | 2026-11-13 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` with only the map up | The turn ended, and Persia opened a `DIPLOMATIC_KUDO` session | 2026-11-13 |
| No call for 45 s with Persia's session open | Still turn 85 | 2026-11-13 |
| `CloseSession` on Persia's session | Kongo proposed a deal. Turn 86 began after the deal was rejected | 2026-11-13 |
| A great merchant moved to `27,31` on turn 391 | `FIRST_MEET_NO_MANS` from Portugal, with Scythia's session queued | 2026-11-13 |
| `AddResponse` with `POSITIVE` on Portugal's greeting, then on the offer | `FIRST_MEET_NO_MANS_INFO_EXCHANGE`, then Portugal's capital revealed and the session closed | 2026-11-13 |
| `AddResponse` with `POSITIVE` on Scythia's greeting, then `CloseSession` | The offer, then the session closed with Scythia's capital still hidden | 2026-11-13 |
| `GetDiplomaticModifiers(0)` for Portugal and Scythia after the meetings | None for Portugal. One +5 with an unknown reason for Scythia | 2026-11-13 |

Date checked: game files on 2026-11-13. Running game on Windows on 2026-11-13.
