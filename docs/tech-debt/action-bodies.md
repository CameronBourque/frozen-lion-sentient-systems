# Action bodies

Each action's whole body is an anonymous function passed to `SentientSystems_RunAction`, so the long ones can't be read, named, or split by step.

## Now

`SentientSystems_RunAction(name, action)` in `packages/core/mod/Scripts/Actions/SentientSystemsCore_Actions.lua` runs `action` in `pcall` and turns a Lua error into a failed result. 

It takes a function with no arguments, so each public action is `return SentientSystems_RunAction("Name", function() <body> end)`.

Eight actions do this. Their bodies, from the call to the closing `end`:

| Action | File | Lines |
| --- | --- | --- |
| `SetProduction` | `SentientSystemsCore_ActionsCities.lua` | 66 |
| `Purchase` | `SentientSystemsCore_ActionsCities.lua` | 53 |
| `SpyMission` | `SentientSystemsCore_ActionsSpies.lua` | 47 |
| `SpyTravel` | `SentientSystemsCore_ActionsSpies.lua` | 44 |
| `TradeRoute` | `SentientSystemsCore_ActionsTrade.lua` | 43 |
| `CityAttack` | `SentientSystemsCore_ActionsCities.lua` | 34 |
| `MoveUnit` | `SentientSystemsCore_ActionsUnits.lua` | 25 |
| `UnitAction` | `SentientSystemsCore_ActionsUnits.lua` | 13 |

Every check and every request in an action sits one level deep in the closure. The steps have no names, and a step can't be tested alone. The city actions already split out helpers such as `FindProductionItem` and `CheckPlacementTile`, but the body that calls them stays long.

## Proposal

Let `RunAction` take the arguments: `SentientSystems_RunAction(name, action, ...)` calls `pcall(action, ...)`. Each action becomes a named local function with its parameters, and the public function is one line that passes them on.

Then split each long body into steps that return the reason or `nil`, such as finding the item, checking the tile, and building the request. Start with `SetProduction` and `Purchase`, the longest, and move the rest as their files change.

## Questions

1. What is the longest an action function should be? A limit, such as 30 lines, lets lint or review catch a new long body.
2. Should a helper define the public global, as in `SentientSystems_DefineAction("SetProduction", SetProduction)`, so no action repeats the one-line wrapper?

## Done when

No action holds its body in a closure passed to `RunAction`. Each action's steps are named functions, and the action functions are within the limit from question 1. The Lua tests and coverage pass unchanged, since they call the public function.
