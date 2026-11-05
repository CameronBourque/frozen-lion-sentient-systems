# Purchase choices

Status: open. The units and buildings each city can buy with gold or faith, and the tiles each city can buy with gold, are confirmed in a running game. District purchases are confirmed in files only. Corps and armies are confirmed in files only.

The calls the purchase choices use to list what each city can buy with gold and faith, as the purchase tabs and the purchase lens list them. The other choices are in the [choices index](README.md). See [design/core/mod/choices.md](../../design/core/mod/choices.md).

## Questions

1. Does a unit's corps and army option read as the purchase tab shows it, once the Nationalism and Mobilization civics allow one?
2. Does a district read as the purchase tab shows it, once Reyna with the Contractor promotion is in the city? Contractor lets a city buy districts with gold.

## What we know now

### Purchases

The panel's purchase tabs list what a city can buy with gold and with faith. `GetData` in `ProductionPanel.lua` tries a unit or a building with gold when its `row.PurchaseYield` is `YIELD_GOLD`, at lines 2188 to 2194 and 2084 to 2090, and tries every district with gold and faith, at lines 2006 to 2016. It tries a unit or a building with faith when its `row.PurchaseYield` is `YIELD_FAITH`, or when `city:GetGold():IsUnitFaithPurchaseEnabled(row.Hash)` or `IsBuildingFaithPurchaseEnabled(row.Hash)` is `true`, at lines 2195 to 2201 and 2091 to 2097. That lets a city buy with faith some items the game marks for gold. `ComposeUnitForPurchase`, `ComposeBldgForPurchase`, and `ComposeDistrictForPurchase`, lines 1632 to 1827, each check an item the same way, with `params[CityCommandTypes.PARAM_UNIT_TYPE]`, `PARAM_BUILDING_TYPE`, or `PARAM_DISTRICT_TYPE` set to its hash, and `params[CityCommandTypes.PARAM_YIELD_TYPE]` to `GameInfo.Yields[<yield>].Index`. Confirmed in files.

- **Listed.** The panel lists the item when `CityManager.CanStartCommand(city, CityCommandTypes.PURCHASE, true, params, false)` returns `true`. Confirmed in files and on Windows on 2026-10-26.
- **Greyed out.** It greys the item out when `CanStartCommand(city, CityCommandTypes.PURCHASE, false, params, true)` returns `false`, with the reasons in `results[CityCommandResults.FAILURE_REASONS]`, or when the player's store of the yield can't afford it: `player:GetTreasury():CanAfford(cityID, hash)` for gold, and `player:GetReligion():CanAfford(cityID, hash)` for faith. The game gives no reason when the player can't afford an item, and `CanStartCommand` returns `false` with no reasons. The panel adds the text of `LOC_BUILDING_INSUFFICIENT_FUNDS`, `Not enough [ICON_Gold] Gold in treasury to purchase this.`, or for faith `LOC_BUILDING_INSUFFICIENT_FAITH`, `Not enough [ICON_Faith] Faith accumulated to purchase this.`. Confirmed in files and on Windows on 2026-10-26.
- **Cost.** `city:GetGold():GetPurchaseCost(yieldIndex, hash)`, and for a unit's corps or army, `GetPurchaseCost(yieldIndex, hash, formation)`. Confirmed in files and on Windows on 2026-10-26.
- **Corps and armies.** When the results have `CityOperationResults.CAN_TRAIN_CORPS` or `CAN_TRAIN_ARMY`, the panel checks the formation again with `params[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE]` set, and `CanAfford(cityID, hash, formation)`. Confirmed in files.

### Tile purchases

`ShowPurchases` in `Base/Assets/UI/WorldView/PlotInfo.lua`, lines 247 to 351, draws the purchase lens. The expansions don't replace the file. It asks for the tiles to buy with `CityManager.GetCommandTargets`, as [placement tiles](placement.md#placement-tiles) does, and reads each tile's gold cost with `city:GetGold():GetPlotPurchaseCost(plotIndex)`, at line 298. It disables a tile's button when the cost is more than `player:GetTreasury():GetGoldBalance()`, and shows `Locale.Lookup("LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE", cost - math.floor(gold))`, such as `You need 18 more [ICON_Gold] in order to purchase this plot.`, at lines 300 to 312. Confirmed in files and on Windows on 2026-10-26.

## Method

1. To change the player's gold, in `GameCore_Tuner`, send `Players[0]:GetTreasury():ChangeGoldBalance(<amount>)`, and the opposite amount afterwards.
2. To see faith purchases, in `GameCore_Tuner`, add a holy site with a shrine as in [choices/production.md](production.md#method), step 2, send `Players[0]:GetReligion():ChangeFaithBalance(600)`, and send `Game.GetGreatPeople():CreatePerson(0, GameInfo.GreatPersonIndividuals["GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA"].Hash, x, y)` for a Great Prophet. Faith added during a turn doesn't allow a pantheon until the next turn: `GetReligion():CanCreatePantheon()` returned `false` with 600 faith. End the turn, pick a pantheon, then found a religion with the prophet.
3. Read the choices as in [choices/production.md](production.md#method), steps 4 and 5.

## Results

A single-player game with Gathering Storm, on turn 14, with one city, Rome, at 3 population, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| Gold purchases for Rome, with 101 gold | Builder 100, scout 60, warrior 80, and slinger 65. Settler 160, battering ram 125, granary 130, and library 180, each greyed out with `Not enough [ICON_Gold] Gold in treasury to purchase this.` and no reason from the game. No district, and no walls. The gold purchase tab showed the same, with the same costs. The choices were 1,742 bytes |
| Faith purchases for Rome, with 0 faith and no religion | No unit, building, or district. `GetReligion():GetFaithBalance()` returned 0. The choices were 1,793 bytes |
| Purchases for Rome on turn 15, with a holy site and a shrine at (17,13) in place of the campus, a pantheon, a religion, 591 faith, and the settler the pantheon gave in Rome | Faith: the missionary at 70, and the Gurdwara at 190, greyed out with `This building requires a Temple building.`. Gold: the settler at 220 and the builder at 100, each greyed out with `Too many units of the same class in this location.`, then the settler with the gold text too. The scout, warrior, slinger, battering ram, and granary as before. Both purchase tabs showed the same, with the same costs. The choices were 1,992 bytes |
| Tiles to buy with gold for Rome on turn 15, with 107 gold | 17 tiles, each 30 or 45 gold, such as (19,14) for 30 and (17,11) for 45, none blocked. The choices were 2,444 bytes |
| The same with 27 gold, after `ChangeGoldBalance(-80)` | Each 45-gold tile blocked with `You need 18 more [ICON_Gold] in order to purchase this plot.`, and each 30-gold tile with `You need 3 more` |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
