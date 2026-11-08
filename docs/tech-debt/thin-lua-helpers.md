# Thin Lua helpers

Some Lua helpers only forward to another function, so a reader hops through names that add nothing.

## Now

Of the 40-odd helpers in `packages/core/mod/Scripts/` whose body is one `return`, most name a real idea, such as `IsAirUnit` or `CanAttack`. The forwarders do not.

`CannotProduce` in `Actions/SentientSystemsCore_ActionsCities.lua` is one call to `WithReasons`, which wraps `FailureReasons`. Three helpers build a reason message for four call sites.

`FailureReasons` is one of six copies of a loop that reads the game's failure reasons from a results table and looks up the text of each. The copies differ only in the results table key and in how the reasons are joined:

| File | Copy | Results key | Returns |
| --- | --- | --- | --- |
| `Choices/SentientSystemsCore_Choices.lua` | `SentientSystems_GetFailureReasons` | `CityCommandResults` | A list |
| `Actions/SentientSystemsCore_ActionsCities.lua` | `FailureReasons` | `CityCommandResults` | A list |
| `Choices/SentientSystemsCore_ChoicesGovernors.lua` | Inline | `PlayerOperationResults` | A list |
| `Choices/SentientSystemsCore_ChoicesSpyMissions.lua` | Inline | `UnitOperationResults` | A list |
| `Actions/SentientSystemsCore_ActionsUnitJobs.lua` | `SentientSystems_GetOperationReasons` | `UnitOperationResults` | The reasons joined with spaces, or nil |
| `Actions/SentientSystemsCore_ActionsUnitUpgrade.lua` | `SentientSystems_GetCommandReasons` | `UnitCommandResults` | The reasons joined with spaces, or nil |

The other copies of the same helper in several files are in [duplicated-code.md](duplicated-code.md).

## Proposal

Follow the shared helper rule in [rules/code.md](../rules/code.md#conventions). One helper in `SentientSystemsCore_Text.lua` reads the failure reasons for every file, with the results key as a parameter. The city actions build their reason message with one local helper on top of it.

## Tasks

1. **Shared failure reasons.** Move `SentientSystems_GetFailureReasons` to `SentientSystemsCore_Text.lua`, which the actions and the choices both include. Give it the results key as a second parameter, and an optional separator that joins the reasons into one string, or nil for none.

   Replace the other five copies with calls to it. `SentientSystems_GetCommandReasons` goes away. `SentientSystems_GetOperationReasons` stays, because it runs the game's check too, and two files call it. Commit: `refactor(core): share one failure reasons helper`.
2. **City action reasons.** In `ActionsCities.lua`, fold `CannotProduce` and `WithReasons` into one `CantNow(start, reasons)` that the four call sites use. `SentientSystems_Purchase` adds its reason for the cost to the list before the call.

   `CantNow` stays local while only this file builds a "now" message with the game's reasons. Commit: `refactor(core): fold the city action reason helpers into one`.

## Done when

No helper in `packages/core/mod/Scripts/` only forwards to another with the same arguments. One function reads the game's failure reasons. The Lua tests and coverage pass.
