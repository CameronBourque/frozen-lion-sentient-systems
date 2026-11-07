# Purchase actions

Status: open. Buying a unit with gold and faith, and a building with gold, are confirmed in a running game. Tile purchases aren't checked yet.

The game call that the purchase action wraps, with the Lua state it runs in and the reasons its checks give. The items a city can buy are in [choices/purchases.md](../choices/purchases.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Buying a unit or a building

`PurchaseUnit` and `PurchaseBuilding` in `Base/Assets/UI/Panels/ProductionPanel.lua`, lines 423 to 479, call `CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, parameters)`. Confirmed in files.

- A unit sets `CityCommandTypes.PARAM_UNIT_TYPE` to its hash and `PARAM_MILITARY_FORMATION_TYPE` to the standard formation. A building sets `PARAM_BUILDING_TYPE`. Both set `PARAM_YIELD_TYPE` to the index of `YIELD_GOLD` or `YIELD_FAITH` in `GameInfo.Yields`.
- A corps and an army differ only in the formation. The action buys the standard unit.
- `PurchaseDistrict`, lines 482 to 522, opens the placement view for a district that needs a tile, and the action doesn't buy districts.
- The action runs in `SentientSystemsCore_UI`. The check is the one the [purchase choice](../choices/purchases.md#purchases) uses: `CanStartCommand` with `testOnly` for the list, and without it for the reasons.
- The game gives no reason when the player can't afford an item, so the reason adds the panel's text. A refusal can carry both the game's reasons and the text.

## Method

1. Read the purchases choice as in [choices/production.md](../choices/production.md#method), step 5.
2. Send the file's code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_Purchase(playerID, cityID, item, yield)`, with the yield `gold` or `faith`.
3. Read `Players[0]:GetTreasury():GetGoldBalance()` or `GetReligion():GetFaithBalance()` before the call and a second after, since the game takes the request a moment later.
4. To test a purchase the player can't afford, in `GameCore_Tuner`, send `Players[0]:GetTreasury():ChangeGoldBalance(<amount>)` to leave about 100 gold, and the opposite amount afterwards.

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`, for player 0 with 12,516 gold and 3,428 faith:

| Check | Result |
| --- | --- |
| `UNIT_MILITARY_ENGINEER` in Aduatuca with gold, listed at 340 | `{"ok":true}`. A second later gold was 12,176, down by 340 |
| `UNIT_NATURALIST` in Alesia with faith, listed at 300 | `{"ok":true}`. A second later faith was 3,128, down by 300 |
| `UNIT_SETTLER` in Aduatuca, blocked in the choice | The game's reason: `Too many units of the same class in this location.` |
| `UNIT_BUILDER` in Alesia with gold set to about 100, after the Naturalist stood in the city center | Both the game's `Too many units of the same class in this location.` and the panel's `Not enough Gold in treasury to purchase this.` |
| `culture` as the yield, `UNIT_NOPE`, and `DISTRICT_CAMPUS` | Reasons that name the yield, the unknown type, and the units and buildings the action buys |

Date checked: 2026-11-07.
