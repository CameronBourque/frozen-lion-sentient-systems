# District choices

Status: confirmed. The districts each city can produce, in `SentientSystems_GetChoices`, are confirmed in a running game. The checks that grey a district out are confirmed in files only.

The calls the production choice uses to list the districts each city can produce, as the production panel lists them. The units, buildings, wonders, and projects are in [choices/production.md](production.md).

The other choices are in the [choices index](README.md). See [design/core/mod/choices.md](../../design/core/mod/choices.md).

## Questions

None open.

## What we know now

### Districts

`GetData` in `ProductionPanel.lua`, lines 1898 to 2018, builds the panel's district list from `GameInfo.Districts()`, before the buildings. For each row, with the city's `GetBuildQueue()` and `GetDistricts()`:

- **Listed.** The panel lists a district when `buildQueue:CanProduce(row.Hash, true)` returns `true` or `cityDistricts:HasDistrict(row.Index)` is `true`.

  It leaves out a row whose `InternalOnly` is `true`, and a one-per-city district that is in production. Confirmed in files and on Windows on 2026-10-26.
- **Built.** For a one-per-city district that the city has, that is complete, not pillaged or contaminated, and has no progress, the panel shows a checkmark in place of turns, in `PopulateDistrictsWithNestedBuildings`, line 953.

  Rome's panel showed **City Center** with a checkmark. Confirmed in files and on Windows on 2026-10-26.
- **Greyed out.** The panel starts from `buildQueue:CanProduce(row.Hash, false, true)`, then checks the tiles from `GetCityRelatedPlotIndexesDistrictsAlternative`.

  With no tile, it greys the district out unless the city has placed it already, and greys a placed one out when a reason is the text of `LOC_DISTRICT_REPAIR_LOCATION_FLOODED`.

  With a tile, it doesn't grey the district out when every reason equals `LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION`. That check compares the reasons with the text key, not its text. Confirmed in files.
- **Cost, progress, turns, and repair.** `buildQueue:GetDistrictCost(row.Index)`, `GetDistrictProgress(row.Index)`, and `GetTurnsLeft(row.DistrictType)`, which takes the type name.

  A district for which `cityDistricts:IsPillaged(row.Index)` is `true` is a repair. Confirmed in files and on Windows on 2026-10-26.

## Method

1. To unlock districts, send `SetTech` for `TECH_WRITING` and `TECH_ASTROLOGY` as in [choices/production.md](production.md#method), step 2.
2. Read the choices as in [choices/production.md](production.md#method), steps 4 and 5.

## Results

A single-player game with Gathering Storm, on turn 14, with one city, Rome, at 3 population, in `SentientSystemsCore_UI`:

- **Districts the panel's checks list for Rome, after `SetTech` for Writing and Astrology.** The campus and the holy site, each 29 cost and 6 turns, not greyed out.

  Each had the tiles (17,13), (16,14), and (16,15), and 8 tiles to buy. The campus had +1 science at (17,13) and (16,15), and +3 science at (19,14), a tile to buy. The city center was left out as built.
- **`SentientSystems_GetChoices` with districts and wonders.** 1,692 bytes.
- **`SentientSystems_GetChoices` without the tiles.** 830 bytes, down from 1,692.
- **Rome's production panel with districts and wonders.** The holy site and the campus at 6 turns, after **City Center** with a checkmark, and the Great Bath and Stonehenge at 14 and the Pyramids and Etemenanki at 18, none greyed out, as in the choices.

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
