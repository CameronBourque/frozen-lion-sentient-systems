# Duplicated code

The same function, constant, or setup is written out in several files of the Lua mod and the bridge, so a fix or a change has to be made in each copy.

## Now

The counts come from a scan of `packages/core/mod/Scripts/`, `packages/core/mod/Test/`, `packages/core/bridge/src/`, and `packages/core/bridge/test/`.

### Lua functions, identical in every copy

| Helper | Body | Copies |
| --- | --- | --- |
| `HasTile`, `IsRaidTile` | A loop that checks a list of tiles for an `x` and `y` | 2, in `ActionsCities` and `ActionsUnitAttacks` |

### Lua code repeated inline

- A city lookup by owner and ID that returns "Player 0 has no city 1." is written 6 times: 4 in `ActionsCities`, 1 in `ActionsSpies`, and 1 in `ActionsTrade`.
- A player lookup that raises `no player <id>` is written 5 times, in the entry files `State`, `Choices`, `Placement`, `TreesGovernors`, and `TreesResearch`.
- The text that lists tiles as "(x, y)" and ends with "and N more" past `MAX_LISTED`, which is 8, is in `ActionsUnitAttacks` and `ActionsUnitTileOrders`.
- The walk over every deal item of a type, with its side and turns left, is in `GetDeals` in `StatePlayerIncome` and `AddDeals` in `StatePlayerResources`. Only the item type and what each does with an item differ.
- The loop over `GameInfo.GovernorPromotionSets` for one governor is in `ChoicesGovernors`, `StateGovernors`, and `TreesGovernors`.
- The unit kind check `row.Combat > 0 and row.Domain ~= "DOMAIN_AIR"` is in `ActionsUnitStances` and `ActionsUnitTiles`.
- The trade route operation parameters `PARAM_X0` to `PARAM_Y1` are built in `ActionsTrade` and `ChoicesTradeRoutes`.
- The `YIELDS` table of yield names is in `Placement` and `StateCities`.

### Lua functions with one name and different bodies

Each pair was read. Only `GetCityRef` is one idea written twice. The others share a name only.

| Name | Files | Fix |
| --- | --- | --- |
| `GetCityRef` | `ChoicesSpyMissions`, `StateEspionage`, and `StateTrade`. All build `{ owner, id, name }`, and only the copy in `StateEspionage` accepts `nil` | Merge |
| `GetPromotions` | `ActionsUnitStances` lists a unit's promotions. `ChoicesGovernors`, `StateGovernors`, and `TreesGovernors` each list a governor's promotions in a different shape | Rename |
| `GetGovernor` | `StateCities`, `StateGovernors`, and `TreesGovernors`, each a different shape | Rename |
| `FindDistrict` | `ActionsSpies` finds a district by type, and `ChoicesSpyMissions` finds one by plot | Rename |
| `GetSpy` | `ActionsSpies` checks that a spy is ready, and `StateEspionage` builds a spy's state entry | Rename |
| `GetActivity`, `GetDistricts`, `GetKind`, `GetProduction` | Two files each, in `State/` and `Actions/`, with unrelated bodies | Rename |

### Lua constants

- `NEED_MORE_GOLD_KEY` is the text key `LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE` in `ActionsCities` and in `ChoicesPurchases`. The keys `LOC_BUILDING_INSUFFICIENT_FUNDS` and `LOC_BUILDING_INSUFFICIENT_FAITH` are in both files too.
- `PURCHASE_YIELDS` in `ActionsCities` repeats the yield, store, and text key of the table with the same name in `ChoicesPurchases`, which has more fields.

### Bridge source

- `CITY`, a city reference of `owner`, `id`, and `name`, is written out in `choices/spy-missions.ts`, `state/espionage.ts`, and `state/trade.ts`.
- An object of the six yields, each an optional number, is in `placement/placement.ts` and `state/income.ts`.
- `describeIssue` formats a zod issue in both `config.ts` and `stash.ts`, and `explainFailure` turns a tuner error into text in both `connect.ts` and `stash.ts`. The wording differs in places.

Other schemas share a name only: `CITY`, `TILE`, `YIELD`, and `PLAYER` each describe a different object in the files that define them. `BLOCKED` in `choices/production.ts` and `choices/purchases.ts` is one line of schema with a different description in each, so it stays.

### Tests

- The block that starts a `FakeGame`, sets its states, connects a `TunerClient`, and closes both after each test appears 18 times in 14 bridge test files.
- In the Lua tests, `Failed` is the same in 15 files, and `Entry` is the same in 3 files. `With`, a shallow copy with changes, is in 24 files, and 20 of them differ only in the name of the first parameter.

## Proposal

Move each copy into one shared helper that takes what differs as parameters, as [rules/code.md](../rules/code.md) says, and delete the rest. Each Lua helper goes in the smallest file that every caller loads:

- `SentientSystemsCore_Math.lua*` holds the rounding.
- `SentientSystemsCore_Lookups.lua*` holds the lookups that the state, the choices, the placement, and the trees share.
- `Actions.lua`, `ChoicesTradeRoutes.lua`, `ChoicesPurchases.lua`, and `Governors.lua` hold what only their own callers use. A file that needs them includes them, as `ActionsSpies` includes `ChoicesSpyMissions`.
- `SentientSystemsCore_Common.lua` keeps its name and holds only what every script needs to run: tagged printing, error catching, and the checked include.

Every core script includes `SentientSystemsCore_Common.lua` before anything else, through its entry file, so the new files load the same way.

In the bridge, `src/schemas.ts*` holds the shared schemas, as [nested-objects.md](nested-objects.md) expects for `Position`. `src/errors.ts*` holds the tuner error text.

## Tasks

Each task is one commit. Each one that adds a file adds its tests, and each Lua file is listed in both file lists of the `.modinfo`.

### Identical Lua helpers

1. Add `SentientSystemsCore_Math.lua` with `SentientSystems_Round(number, places)`, where `places` is 0 when left out.
2. Move the `State/` files to `SentientSystems_Round`, delete their 10 rounding helpers, and replace the inline rounding in `StateCities`.
3. Move `RoundYield` in `ChoicesTradeRoutes` to `SentientSystems_Round`.
4. Move `HasTile` and `IsRaidTile` into `SentientSystems_HasTile(tiles, x, y)` in `Actions.lua`.

### Repeated Lua code

5. Add `SentientSystems_ListTiles(tiles)` with `MAX_LISTED` to `Actions.lua`, and use it in `ActionsUnitAttacks` and `ActionsUnitTileOrders`.
6. Add `SentientSystems_FindCity(playerID, cityID)` to `Actions.lua`. It returns the city, or `nil` and the reason. Use it in the 6 city lookups.
7. Move the unit kind check of pillage and plunder into one function in `ActionsUnits.lua`.
8. Add `SentientSystems_GetRouteParams(city, unit)` to `ChoicesTradeRoutes`, and use it in `ActionsTrade`, which already includes that file.
9. Add a walk over a player's deal items of one type to `StatePlayer.lua`, above its includes, and use it in `GetDeals` and `AddDeals`.
10. Add `SentientSystems_GetPromotionRows(definition)` to `Governors.lua`, and use it in the three governor `GetPromotions`.
11. Add `SentientSystemsCore_Lookups.lua` with `SentientSystems_GetPlayer(playerID)`, which raises `no player <id>`, and use it in the 5 entry files.
12. Merge `GetCityRef` into `SentientSystems_GetCityRef(city)` in `Lookups.lua`, which returns `nil` for `nil`, and delete the 3 copies.
13. Move `YIELDS` into `Lookups.lua` as `SENTIENTSYSTEMS_YIELDS`, and use it in `Placement` and `StateCities`.

### Lua constants

14. Make `PURCHASE_YIELDS` and the 3 text keys global in `ChoicesPurchases`. `ActionsCities` includes that file and deletes its copies.

### Bridge source

15. Add `src/schemas.ts` with the city reference, and use it in the 3 files.
16. Add the yields object to `src/schemas.ts`, and use it in `placement/placement.ts` and `state/income.ts`.
17. Add `src/errors.ts` with one `describeIssue` that keeps the unknown field case of `config.ts`, and use it in `config.ts` and `stash.ts`.
18. Move `explainFailure` into `src/errors.ts`, with the request name and the retry text as parameters, and use it in `connect.ts` and `stash.ts`.

### Tests

19. Add `startGame(states)` to `test/tuner/fake-game.ts`, which returns the game and the client and closes both after each test. Use it in `test/actions/`.
20. Use `startGame` in the other 9 bridge test files.
21. Add `Test/Helpers.lua` with `With`, `Failed`, and `Entry`, and use it in the Lua tests. Keep a local `With` where the body differs.

### Names with different bodies

22. Rename the 4 `GetPromotions` and the 3 `GetGovernor` to names that say what each returns.
23. Rename `GetSpy` and `FindDistrict` in `ActionsSpies`, `ChoicesSpyMissions`, and `StateEspionage`.
24. Rename `GetActivity`, `GetDistricts`, `GetKind`, and `GetProduction`, so each name has one definition.

### Record

25. Add the homes of the shared helpers to the `## Decisions` table of [design/core/mod/README.md](../design/core/mod/README.md), and update [nested-objects.md](nested-objects.md). Delete this file and its index row.

## Done when

No function or constant in the lists above has more than one definition. The names with different bodies are merged or renamed. The tests start the fake game in one helper. The Lua tests, the bridge tests, and coverage pass.
