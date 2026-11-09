# City Status tab

Status: open. The City Status tab's growth rate, war weariness, and governor, which sit in `cities`, are confirmed in a running game with Gathering Storm.

The calls the state uses for the City Status tab of Reports. The top bar is in [state/player.md](../player.md). See [design/core/mod/state.md](../../../design/core/mod/state.md) and the [Reports index](README.md).

## Questions

None open.

## What we know now

`CreateCityStatusInstance` in `ReportScreen.lua`, which the Rise and Fall `ReportScreen_Expansion1.lua` replaces for Rise and Fall and Gathering Storm, builds each row from `GetCityData` in `CitySupport.lua`.

The Rise and Fall row drops the base game's Under Siege column and adds loyalty and the governor. Confirmed in files.

- **Growth rate status.** `GetHousingGrowthModifier()` of 0, or `IsOccupied()`, is Halted, a modifier of 0.5 or less is Slowed, `GetHappinessGrowthModifier()` above 0 is Accelerated, and anything else is Normal.

  The save's cities had modifiers of 1, 0.5, and 0.25, and no happiness modifier. Confirmed in files and on Windows on 2026-10-29.
- **War weariness and governor.** `GetAmenitiesLostFromWarWeariness()` is the amenities lost, which the tab shows as 0 or a negative number.

  `GetAssignedGovernor()`, which a city has only with Rise and Fall, gives the governor's type and `IsEstablished()`, which picks the icon's fill. Confirmed in files and on Windows on 2026-10-29.

## Method

1. Send `SentientSystemsCore_StateCities.lua` without its comments, then print each city's `growth.rate`, `amenities`, and `governor`, and compare with the tab.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

- **The City Status tab on the same save.** The 15 cities' growth rates matched the tab row for row, with 8 slowed and 7 normal, the amenities had and needed matched, war weariness was 0 for all, and the governors on Aduatuca, Samarobriva, and Cenabum matched its icons.

  Halted, accelerated, and war weariness above 0 weren't on the save, and are tested against the fake game only.

Date checked: game files and a running game on Windows on 2026-10-29, and game files on 2026-11-07.
