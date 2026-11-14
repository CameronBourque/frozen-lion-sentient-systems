# AI requests and promises

Status: open. The troop, settling, and spying promises, the delegation, the embassy, and the friendship request are confirmed in a running game with Gathering Storm, with calls sent through the tuner. The other requests are confirmed in files only.

The leader screen sessions where an AI asks the player for something, such as a delegation, an embassy, or a promise. How a session is read and answered is in [ai-sessions.md](ai-sessions.md), with the options of each statement.

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. What do open borders, friendship, and an alliance request do when answered? Record the follow-up statement for each response, and whether the game closes the session after it.
2. Why did refusing Ethiopia's embassy still place it? The game may place an embassy with no answer needed, or count `NEGATIVE` as no answer.

## What we know now

### Promises

Moving troops near Persia and Brazil on turn 54 brought `WARNING_TOO_MANY_TROOPS_NEAR_ME` from each, with Brazil's queued behind Persia's.

Its options are `CHOICE_POSITIVE`, the promise, and `CHOICE_NEGATIVE`, which declares war through `DIPLOACTION_DECLARE_SURPRISE_WAR`. Confirmed on Windows on 2026-11-13.

`AddResponse` with `POSITIVE` brought Persia's reply in the same session, "Thank you.", with only `CHOICE_EXIT`. The closing listener closed it, and Brazil's statement came next. Confirmed on Windows on 2026-11-13.

`AddResponse` with `NEGATIVE` on Brazil's warning declared war on Brazil. Brazil's reply, `DECLARE_SURPRISE_WAR`, came in the same session with only `CHOICE_EXIT`, and the closing listener closed it. Confirmed on Windows on 2026-11-13.

Vietnam's `WARNING_STOP_SPYING_ON_ME` on turn 97 uses the `WARNING_STOP_SPYING_ON_ME_FROM_AI` options, `CHOICE_POSITIVE` and `CHOICE_NEGATIVE`, with 30 Diplomatic Favor and 25 grievances in their text. Brazil's session waited behind it. Confirmed on Windows on 2026-11-13.

While Vietnam's promise was open, Vietnam's incoming working deal still held six items of an old peace deal: two `MAKE_PEACE` agreements, a city to cede, gold, and a captive spy.

`GetValueTypeNameID` returned nothing for the captive. An open session with items in the incoming deal is no sign of a proposal. Confirmed on Windows on 2026-11-13.

Vietnam's `WARNING_TOO_MANY_TROOPS_NEAR_ME` on turn 97, after the player's spy came home, offered `CHOICE_NEGATIVE` disabled.

`IsDiplomaticActionValid` for `DIPLOACTION_DECLARE_SURPRISE_WAR` failed with the reason "Unable to Surprise War" and a line that a friend or ally of the player's team is on Vietnam's team. Confirmed on Windows on 2026-11-13.

That line is wrong. The game had no teams, and the player had no friends or allies. The real cause was the peace deal that returned the player's spy, after which war on Vietnam waits 10 turns.

The game's reason may be a bug, and the state passes it on as the leader screen shows it. Confirmed on Windows on 2026-11-13.

### Requests

Egypt's `DIPLOMATIC_DELEGATION` on turn 15 used the `DELEGATION_FROM_AI` options: `CHOICE_POSITIVE`, `CHOICE_NEGATIVE`, and `CHOICE_EXIT`, none with a `DiplomaticActionType`.

`AddResponse` with `POSITIVE` placed Egypt's delegation at the player, and Egypt's reply, "Excellent!", came in the same session with only `CHOICE_EXIT`. The closing listener closed it. Confirmed on Windows on 2026-11-13.

Ethiopia's `RESIDENT_EMBASSY` on turn 92 used the `EMBASSY_FROM_AI` options, the same three. `AddResponse` with `NEGATIVE` brought the reply "Disappointing.", which the listener closed, yet `HasEmbassyAt(0)` for Ethiopia went from `false` to `true`. Confirmed on Windows on 2026-11-13.

Brazil's `WARNING_DONT_SETTLE_NEAR_ME` on turn 92 gives each option's effect in its text: 30 Diplomatic Favor for the promise, and 25 grievances for the refusal. The text holds `[SIZE_12]` and `[SIZE_18]` tags around it, and the grievance icon. Confirmed on Windows on 2026-11-13.

Kongo's `DECLARE_FRIEND` on turn 117 used the `DECLARE_FRIEND_FROM_AI` options: `CHOICE_POSITIVE`, `CHOICE_NEGATIVE`, `CHOICE_STOP_ASKING`, and `CHOICE_EXIT`, none with a `DiplomaticActionType`. The sessions section listed all four, since Kongo is an AI.

Kongo had been made a declared friend through `SetHasDeclaredFriendship` in `GameCore_Tuner` on turn 92. Confirmed on Windows on 2026-11-13.

With the request up, Kongo's incoming working deal held an old 100 gold gift, which the proposals section listed before the fix for old deals loaded. Confirmed on Windows on 2026-11-13.

## Method

1. Add the listeners in step 1 of the [AI sessions method](ai-sessions.md#method), or load the core mod, whose sessions section lists each statement.
2. Load a save with a request or a promise up, or move troops next to an AI's border, settle near its cities, or buy tiles near them, and end the turn.
3. To answer, send `AddResponse` with the response. Read the follow-up statement, the messages, and the change, such as `HasDelegationAt`, `HasEmbassyAt`, or `IsAtWarWith`.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Call | Result | Date |
| --- | --- | --- |
| Troops moved near Persia and Brazil on turn 54, with the sessions section | Persia's `WARNING_TOO_MANY_TROOPS_NEAR_ME` with both options enabled, and Brazil's session queued | 2026-11-13 |
| `AddResponse` with `POSITIVE` on Persia's warning | Persia's reply closed with a message, and Brazil's warning came up | 2026-11-13 |
| `AddResponse` with `NEGATIVE` on Brazil's warning | `IsAtWarWith(11)` went from `false` to `true`. Brazil's war reply closed with a message, and no session was left open | 2026-11-13 |
| `AddResponse` with `POSITIVE` on Egypt's `DIPLOMATIC_DELEGATION` on turn 15 | `HasDelegationAt(0)` for Egypt went from `false` to `true`. Egypt's reply closed with a message, and no session was left open | 2026-11-13 |
| `AddResponse` with `NEGATIVE` on Ethiopia's `RESIDENT_EMBASSY` on turn 92 | The reply closed with a message, and Ethiopia's embassy was placed anyway | 2026-11-13 |
| Turn 97, with Vietnam's `WARNING_STOP_SPYING_ON_ME` up | The sessions section listed it with Brazil queued. `SentientSystems_GetState(0)` failed on the old peace deal's captive, which has no name | 2026-11-13 |
| Turn 117, with Kongo's `DECLARE_FRIEND` up | The sessions section listed the four options, with stop asking. The proposals section listed an old 100 gold gift from Kongo | 2026-11-13 |
| Turn 94 after a reload, with Brazil's `WARNING_STOP_SPYING_ON_ME` up | The state built, with no proposals, though Vietnam's incoming deal still held five old peace items. The option text had no size tags. The grievance icon, `[ICON_STAT_GRIEVANCE]`, still read as words | 2026-11-13 |
| Turn 97, with Vietnam's `WARNING_TOO_MANY_TROOPS_NEAR_ME` up | The state built with no proposals, though Vietnam's incoming deal held the old peace items and a captive with no name. The war option was disabled, with a reason that names teams instead of the peace deal's 10 turns | 2026-11-13 |

Date checked: game files on 2026-11-13. Running game on Windows on 2026-11-13.
