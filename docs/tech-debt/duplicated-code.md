# Duplicated code

The same function, constant, or setup is written out in several files of the Lua mod and the bridge, so a fix or a change has to be made in each copy.

## Now

The counts come from a scan of `packages/core/mod/Scripts/`, `packages/core/bridge/src/`, and `packages/core/bridge/test/`.

### Lua functions, identical in every copy

| Helper | Body | Copies |
| --- | --- | --- |
| `RoundNearest`, `RoundTenth` | `math.floor(number * 10 + 0.5) / 10` | 6, in `StateCities`, `StatePlayer`, `StatePlayerIncome`, `StateVictories`, `StateVictoriesScience`, and `StateGreatPeople` |
| `RoundProgress` | `math.floor(progress * 1000 + 0.5) / 1000` | 2, in `StateVictories` and `StateVictoriesScience` |
| `RoundWhole`, `Round` | `math.floor(number + 0.5)` | 2, in `StateCities` and `StateScoreboard` |
| `HasTile`, `IsRaidTile` | A loop that checks a list of tiles for an `x` and `y` | 2, in `Actions/SentientSystemsCore_ActionsCities.lua` and `ActionsUnitAttacks.lua` |

### Lua functions with one name and different bodies

Each of these is defined in more than one file, and the bodies differ. Some are the same idea with small differences, and some only share a name. Nobody has checked which.

| Name | Files |
| --- | --- |
| `GetCityRef` | `ChoicesSpyMissions`, `StateEspionage`, and `StateTrade`. The first and the last build the same `{ owner, id, name }` |
| `GetPromotions` | `ActionsUnitStances`, `ChoicesGovernors`, `StateGovernors`, and `TreesGovernors` |
| `GetGovernor` | `StateCities`, `StateGovernors`, and `TreesGovernors` |
| `FindDistrict`, `GetSpy` | `ActionsSpies`, and for `FindDistrict` also `ChoicesSpyMissions`, for `GetSpy` also `StateEspionage` |
| `GetActivity`, `GetDistricts`, `GetKind`, `GetProduction` | Two files each, in `State/`, `Actions/`, and `Choices/` |

### Lua constants

- `NEED_MORE_GOLD_KEY` is the text key `LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE` in `ActionsCities` and in `ChoicesPurchases`. The keys `LOC_BUILDING_INSUFFICIENT_FUNDS` and `LOC_BUILDING_INSUFFICIENT_FAITH` are in both files too.
- `PURCHASE_YIELDS` in `ActionsCities` repeats the yield, store, and text key of the table with the same name in `ChoicesPurchases`.
- `MAX_LISTED` is 8 in `ActionsUnitAttacks` and `ActionsUnitTileOrders`.

### Bridge source

- `CITY`, a city reference of `owner`, `id`, and `name`, is written out in `choices/spy-missions.ts`, `state/espionage.ts`, and `state/trade.ts`. The Lua side builds the same shape in the `GetCityRef` copies above.
- `describeIssue` formats a zod issue in both `config.ts` and `stash.ts`, and `explainFailure` turns a tuner error into text in both `connect.ts` and `stash.ts`. The wording differs in places.
- `BLOCKED` is a list of the game's reasons in `choices/production.ts` and `choices/purchases.ts`, with different descriptions.

Other schemas share a name only: `CITY`, `TILE`, `YIELD`, and `PLAYER` each describe a different object in the files that define them.

### Bridge tests

The block that starts a `FakeGame`, sets its states, connects a `TunerClient`, and closes both after each test appears 18 times in 14 files. `test/actions/cities.test.ts` holds it 4 times, once for each action in the file.

## Proposal

Move each identical copy to a shared file and delete the rest.

In Lua, `SentientSystemsCore_Common.lua` holds the rounding helpers and the tile check. A text keys file, or the same file, holds the keys and limits that two files share.

In the bridge, a `src/schemas.ts` holds the shared schemas, and the tuner error text moves to one place.

For the tests, one helper starts the fake game and the client and returns both, and each file calls it from `beforeEach`.

For the names with different bodies, read each pair first. Merge the ones that are the same idea, and rename the ones that are not, so a search finds one meaning for a name.

Work one helper at a time, one commit each. Do the identical copies first, then the constants, then the schemas, the tests, and last the different bodies.

## Questions

1. Does every file that needs a shared Lua helper load `SentientSystemsCore_Common.lua` first? The state, choices, and actions files load in one Lua state, but a file loaded earlier would need an include.
2. Do `PURCHASE_YIELDS` in the actions and the choices stay two tables, or does one file own it? The choices use more fields than the actions.
3. Do the shared schemas belong in one `src/schemas.ts`, or next to the first schema that uses each?

## Done when

No function or constant in the lists above has more than one definition. The names with different bodies are merged or renamed. The tests start the fake game in one helper. The Lua tests, the bridge tests, and coverage pass.
