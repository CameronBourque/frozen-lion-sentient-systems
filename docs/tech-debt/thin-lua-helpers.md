# Thin Lua helpers

Some Lua helpers only forward to another function, and others are copied into several files, so a reader hops through names that add nothing or finds the same code in many places.

## Now

Of the 40-odd helpers in `packages/core/mod/Scripts/` whose body is one `return`, most name a real idea, such as `IsAirUnit` or `CanAttack`. Two groups do not.

**Forwarders.** `CannotProduce` in `Actions/SentientSystemsCore_ActionsCities.lua` is one call to `WithReasons`, which wraps `FailureReasons`. Three helpers build a reason message for four call sites.

**Copies of the same helper.** Each is defined in its own file:

| Helper | Body | Copies |
| --- | --- | --- |
| `RoundNearest`, `RoundTenth` | `math.floor(number * 10 + 0.5) / 10` | 6, in `StateCities`, `StatePlayer`, `StatePlayerIncome`, `StateVictories`, `StateVictoriesScience`, and `StateGreatPeople` |
| `RoundProgress` | `math.floor(progress * 1000 + 0.5) / 1000` | 2, in `StateVictories` and `StateVictoriesScience` |
| `RoundWhole`, `Round` | `math.floor(number + 0.5)` | 2, in `StateCities` and `StateScoreboard` |
| `GetCityRef` | `{ owner, id, name }` of a city | 2, in `Choices/SentientSystemsCore_ChoicesSpyMissions.lua` and `State/SentientSystemsCore_StateTrade.lua` |

The shared file `SentientSystemsCore_Common.lua` holds code that every file uses, and these helpers are not in it.

## Proposal

Inline a helper that only renames a call, or fold a chain of them into one. Move each copied helper to `SentientSystemsCore_Common.lua` with one name, and delete the copies. Keep a one-line helper that names an idea or gives a long expression a short name.

Do the city action helpers first, since the code is new, then the copies, one commit per helper.

## Questions

1. What separates a helper that names an idea from one that only renames a call? A test, such as "more than one caller, or a name that explains a condition", would settle the rest.
2. Does every file that needs the rounding helpers load `SentientSystemsCore_Common.lua` first? The state files and the choices files load in the same Lua state, but a file that does not would need an include.

## Done when

Each copied helper has one definition in `SentientSystemsCore_Common.lua`. No helper in `packages/core/mod/Scripts/` only forwards to another with the same arguments. The Lua tests and coverage pass.
