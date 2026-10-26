# Game captured cities

Status: open. The `capturedCities` key of `SentientSystems_GetChoices`, what the player can do with a city they captured, is confirmed in a running game with Gathering Storm, with the file sent through the tuner, and matches the raze screen's buttons and tooltips. Its rebelled city, from Rise and Fall's disloyal city screen, is confirmed only in files.

The calls the captured city choice uses, as the raze and disloyal city screens show them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the disloyal city screen offer the same city and options as the choice, once a city rebels to join the player?

## What we know now

### Raze screen

`Base/Assets/UI/Popups/RazeCity.lua` draws the raze screen, and Gathering Storm replaces its `OnOpen` with the one in `RazeCity_Expansion2.lua`, which words each cost in grievances and favor instead of warmonger levels. Rise and Fall doesn't change it. Confirmed in files.

- **City.** `OnOpen`, lines 64 to 145, reads the player's `GetCities():GetNextCapturedCity()`, one city at a time, and shows its name, `GetPopulation()`, and `GetDistricts():GetNumZonedDistrictsRequiringPopulation()`. Caguana showed 1 and 0. Confirmed in files and on Windows on 2026-10-26.
- **Liberate.** **Liberate to Founder** shows when `GetOriginalOwner()` differs from `GetOwnerBeforeOccupation()` and from `GetJustConqueredFrom()`, and the player's `GetDiplomacy():CanLiberateCityTo(originalOwner)` is `true`. **Liberate to Previous Owner** shows when `CanLiberateCityTo(ownerBefore)` is `true` and that owner isn't the one the city was taken from. With Gathering Storm, the tooltip names the favor from `GlobalParameters`: `FAVOR_FOR_LIBERATE_PLAYER_CITY`, or `FAVOR_FOR_LIBERATE_CITY_STATE` for a city-state's city, plus `FAVOR_FOR_REVIVE_PLAYER` for a major player with no cities whom the player's `GetStats():GetHasRevivedPlayer` hasn't revived. Both favors for liberating were 100. For Caguana, taken from its founder, both checks were `false`, and the screen showed neither. Confirmed in files and on Windows on 2026-10-26.
- **Command check.** `CityManager.CanStartCommand(city, CityCommandTypes.DESTROY, params)` was `true` for both liberate directives on Caguana, though the screen hides them, and `false` only for `REJECT`. The choice follows the screen's checks. Confirmed on Windows on 2026-10-26.
- **Keep and raze.** **Keep City** always shows, and **Raze City** is off when `CanRaze()` is `false`, with `LOC_RAZE_CITY_RAZE_DISABLED_EXPLANATION`. Each tooltip names the cost from `ComputeCityWarmongerPoints(city, conqueredFrom, raze)`: a level from `GetWarmongerLevel(-points)` in the base game, and grievances with Gathering Storm. A city from `CityTransferTypes.BY_GIFT` and, with Gathering Storm, a Free City from `IsFreeCities()` have their own text. When the player it was taken from has no city left, the text is for a final city, and Gathering Storm multiplies the cost of keeping it by `WARMONGER_FINAL_MAJOR_CITY_MULTIPLIER`, 200. Caguana's points were 50 to keep and 100 to raze, and both tooltips named 100 grievances. Confirmed in files and on Windows on 2026-10-26.
- **Sending.** Each button sends `CityManager.RequestCommand(city, CityCommandTypes.DESTROY, params)` with the directive in `params[UnitOperationTypes.PARAM_FLAGS]`: `CityDestroyDirectives.LIBERATE_FOUNDER`, `LIBERATE_PREVIOUS_OWNER`, `KEEP`, or `RAZE`, which were 0 to 3. Confirmed in files and on Windows on 2026-10-26.

### Disloyal city screen

`DLC/Expansion1/UI/Additions/DisloyalCityChooser.lua`, the same in Gathering Storm, draws the disloyal city screen. Confirmed in files.

- **City and options.** `OnOpen`, lines 27 to 56, reads `GetCities():GetNextRebelledCity()`, which only Rise and Fall's cities have, and shows the same name, population, and districts as the raze screen. **Keep** sends `CityDestroyDirectives.KEEP` and **Refuse** sends `REJECT`, 4, with fixed tooltips, `LOC_DISLOYAL_CITY_CHOOSER_KEEP_EXPLANATION` and `LOC_DISLOYAL_CITY_CHOOSER_REFUSE_EXPLANATION`, which leaves it a Free City. Confirmed in files.

## Method

1. To read a choice that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, and send `SentientSystemsCore_Choices.lua` again so it calls it.
2. To capture a city, while at war with its owner, send `UnitManager.InitUnit(0, "UNIT_GIANT_DEATH_ROBOT", x, y)` in `GameCore_Tuner` on a tile next to it. One attack only took 30 from the walls, so first send `SetDamage(DefenseTypes.DISTRICT_GARRISON, 199)` and `SetDamage(DefenseTypes.DISTRICT_OUTER, 100)` on its center, from `city:GetDistricts():GetDistrict(GameInfo.Districts["DISTRICT_CITY_CENTER"].Index)`. Then attack from the UI state with `UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, params)`, with `PARAM_X`, `PARAM_Y`, and `PARAM_MODIFIERS` set to `UnitOperationMoveModifiers.ATTACK`.

## Results

A single-player game with Gathering Storm, on turn 3 of the save with 18 city-states, at war with Caguana, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The choices after a GDR took Caguana, its only city | `[{"city":131073,"districts":0,"kind":"captured","name":"Caguana","options":[KEEP,RAZE],"population":1,"x":47,"y":40}]`, each option with its final-city tooltip naming 100 grievances. `ENDTURN_BLOCKING_CONSIDER_RAZE_CITY` with `"choice":"capturedCities"`. The raze screen showed **Keep City** and **Raze City**, population 1, and 0 districts, and each button's tooltip read the same as its description |
| The choices through the bridge's readers | Parsed, with the same values |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
