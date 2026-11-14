# AI diplomacy sessions

Status: open. Comments, closing them from a listener, and how an open session holds the turns are confirmed in a running game with Gathering Storm, with calls sent through the tuner.

The game calls that read and answer a session an AI opens with no deal, such as a comment, a request, or a first meeting, with the Lua state they run in.

The first meetings are in [first-meetings.md](first-meetings.md), and the requests and promises in [ai-requests.md](ai-requests.md). Sessions that hold a deal are in [diplomacy.md](diplomacy.md). Declaring war and proposing peace are in [war-and-peace.md](war-and-peace.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. Do two AIs open sessions with each other, out of sight of the UI state? See [between two AIs](#between-two-ais), and the [computer slot test](../../design/agents/slot-type.md#computer-slot-test).

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

`DiplomacySupport_RemoveInvalidSelections` then checks each option's `DiplomaticActionType` with `IsDiplomaticActionValid`. A failed option with `FailureReasons` stays, disabled, with the first reason as its tooltip. One without is removed. Confirmed in files.

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
| The five `FIRST_MEET` statements: `NEAR_RECIPIENT`, `VISIT_RECIPIENT`, `NEAR_INITIATOR`, `NO_MANS`, and `NO_MANS_INFO_EXCHANGE` | `CHOICE_POSITIVE` and `CHOICE_EXIT` | See [first-meetings.md](first-meetings.md) |

A promise has no `CHOICE_EXIT` until it is answered. For most promises, the text of `CHOICE_POSITIVE` gives 30 Diplomatic Favor, and the text of `CHOICE_NEGATIVE` gives 25 Grievances.

For `WARNING_TOO_MANY_TROOPS_NEAR_ME`, `CHOICE_NEGATIVE` declares war. Confirmed on Windows on 2026-11-13, from `Locale.Lookup` of the option text.

### Comments

After a war on the Maori, Scythia opened a `DIPLOMATIC_WARNING` session. Its only option was `CHOICE_EXIT`. Later wars on the Cree and the Netherlands in the same turn brought no comment. Confirmed on Windows on 2026-11-13.

During the AI turns, Persia opened a `DIPLOMATIC_KUDO` session. The AI turns stopped until `CloseSession` closed it. Kongo then proposed a deal, and the turn went on after `SentientSystems_RespondToDeal` rejected it. Confirmed on Windows on 2026-11-13.

### Closing a goodbye

A listener on `Events.DiplomacyStatement` in `SentientSystemsCore_UI` called `CloseSession` as soon as a statement from an AI offered only `CHOICE_EXIT`.

The game sent `Events.DiplomacySessionClosed` for each, and the AI turns went on. The screen showed a short black flash, and no leader screen came up. Confirmed on Windows on 2026-11-13.

It closed these statements:

- The Maori leader's reply to `SentientSystems_DeclareWar`, `DECLARE_SURPRISE_WAR`. The player opened that session, so `Initiator` was the player. This is the goodbye the war action leaves up. See [declaring war](war-and-peace.md#declaring-war).
- Scythia's `DIPLOMATIC_WARNING` and Persia's `DIPLOMATIC_KUDO`.
- The Netherlands' `DIPLOMATIC_HIDDEN_AGENDA_WARNING` and `DENOUNCE`.

Right after the call, `IsSessionIDOpen` returned `false` for the war reply and `true` for the others, and the close event came in the same second.

### Between two AIs

Over six AI turns, from turn 85 to turn 91, the listener saw 15 statements. Every one went from an AI to the player, and none went between two AIs. The UI state may get this event only for sessions with the local player. Confirmed on Windows on 2026-11-13.

### What an open session stops

The game won't save with a leader screen up. The player has to leave the screen first, so a save made from the menu holds no open session. Confirmed on Windows on 2026-11-13.

A session waits behind another open session, and a war request then fails. See [declaring war](war-and-peace.md#declaring-war).

An end turn request with a leader screen up closes the screen and doesn't end the turn. See [ending the turn](end-turn.md#ending-the-turn).

## Method

1. Add a listener to `Events.DiplomacyStatement` in `SentientSystemsCore_UI` that logs `os.clock()`, each field of `kVariants`, and `DiplomacyManager.GetKeyName` of each number. Add one to `Events.DiplomacySessionClosed`.
2. To get a comment, declare war on a major civ with `SentientSystems_DeclareWar`, or end the turn. Read the log and `DiplomacyManager.GetSessionInfo` of each session from `FindOpenSessionID`.
3. To list the options, read `GameInfo.DiplomacyStatements` and `GameInfo.DiplomacySelections` for the rows with `ANY` leader and mood, and the `Locale.Lookup` of each option's text.
4. To answer, send `AddResponse` with the response, or `CloseSession` for `CHOICE_EXIT`. Read the log, the turn, and `PlayersVisibility[0]:IsRevealed` on the other player's capital.
5. To close the goodbyes, call `CloseSession` in the listener when the statement's options for `ANY` leader and mood are only `CHOICE_EXIT`, the sender is an AI, and the statement isn't `MAKE_DEAL`.

   End turns, reject each deal with `SentientSystems_RespondToDeal`, and log whether each player is human.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| `SentientSystems_DeclareWar(0, 4)` on turn 85 | Scythia's `DIPLOMATIC_WARNING` session opened, with only `CHOICE_EXIT` | 2026-11-13 |
| `SentientSystems_DeclareWar(0, 1)`, then `(0, 7)` | No comment from any player | 2026-11-13 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` with only the map up | The turn ended, and Persia opened a `DIPLOMATIC_KUDO` session | 2026-11-13 |
| No call for 45 s with Persia's session open | Still turn 85 | 2026-11-13 |
| `CloseSession` on Persia's session | Kongo proposed a deal. Turn 86 began after the deal was rejected | 2026-11-13 |
| `SentientSystems_DeclareWar(0, 4)` on turn 85, with the closing listener | The Maori reply and Scythia's warning closed. A black flash, and no leader screen | 2026-11-13 |
| End turns 85 to 90, with the closing listener | Persia's kudo and the Netherlands' warning and denouncement closed. Five deals held the turns until rejected. No statement between two AIs | 2026-11-13 |

Date checked: game files on 2026-11-13. Running game on Windows on 2026-11-13.
