# Great works in the state

Status: in progress. The slots, theme progress, yields, locks, and header totals are confirmed in a running game with Gathering Storm. Auto theming is not yet compared.

The calls the great works in the state use, as the Great Works screen shows them. The moves of a work and the map layers are in later sections. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

- Does `culture:IsAutoThemedEligible()` with no argument, as the Expansion 2 screen calls it, give the same answer as the screen's progress label?

## What we know now

### The screen

`Base/Assets/UI/GreatWorksOverview.lua` draws the screen, and `DLC/Expansion2/UI/Replacements/GreatWorksOverview_Expansion2.lua` replaces `PopulateGreatWorkSlot` with a version that adds tourism and auto theming. Confirmed in files.

- **Buildings.** `UpdateGreatWorks` walks the player's cities and every `GameInfo.Buildings()` row that `GetBuildings():HasBuilding` accepts and `GetNumGreatWorkSlots` gives more than 0 slots.

  The header shows the works and the spaces, which are the sums over those buildings.
- **A slot.** `GetGreatWorkSlotType(building, slot)` indexes `GameInfo.GreatWorkSlotTypes`. `GetGreatWorkInSlot(building, slot)` gives the work's index, or -1 for an empty slot. 

  `GetGreatWorkTypeFromIndex(index)` indexes `GameInfo.GreatWorks`, which has the name, `GreatWorkObjectType`, `EraType`, and `Tourism`. The yields are in `GameInfo.GreatWork_YieldChanges()`.
- **Theming.** `IsBuildingThemedCorrectly(building)` gives the bonus. The progress label counts the works that `GreatWorkFitsTheme` accepts, or all the works when `culture:IsAutoThemedEligible()` is true.

  A work fits a building that is themed correctly, and the first work always fits the two museums. In the art museum, a work fits when its creator is new and its object type is the first work's.

  In the artifact museum, a work fits when its era is the first work's and no two works come from the same civilization (`Game.GetGreatWorkPlayer`).

  The bonus text is `LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM` for the auto themed building, and otherwise the `ThemingBonusDescription` of `GameInfo.Building_GreatWorks()`.

  Auto theming is a civilization trait, `MODIFIER_PLAYER_ADJUST_AUTO_THEMED_BUILDING`. The museum it names counts as themed once it is full, with the text "Theming bonus doubling output when museum is full."
- **Theming rules.** `GameInfo.Building_GreatWorks()` has the rules of a full theme as columns, which the screen shows only as the bonus text: `ThemingUniquePerson`, `ThemingSameObjectType`, `ThemingSameEras`, `ThemingUniqueCivs`, `ThemingYieldMultiplier`, and `ThemingTourismMultiplier`.

  In `Base/Assets/Gameplay/Data/Buildings.xml`, the art museum has unique creators and one object type, and the artifact museum has one era and unique civilizations. Both have 3 slots and double the yield and the tourism.

  The palace, Hermitage, Broadway, and the other buildings have none. A full theme needs every slot filled and every rule met, so the state gives the rules and the building's slot count.
- **Slots of one building.** One building can mix kinds. Broadway has 1 writing slot and 2 music slots, and the Hermitage has 4 art slots.

  The palace slot is `GREATWORKSLOT_PALACE`, which takes every object type. `GameInfo.GreatWork_ValidSubTypes()` maps a slot kind to the object types it takes, which the empty slot's tooltip lists. The state gives them as `accepts` on each slot.
- **Moving.** `CanMoveWorkAtAll` locks art, which is the sculpture, portrait, religious, and GREATWORKOBJECT_LANDSCAPE objects, until `GetTurnFromIndex(work) + GlobalParameters.GREATWORK_ART_LOCK_TIME` (10 when unset) has passed.

  The turn is when the work was created or moved in, and the screen's pop-up says how many turns are left. 

  An artifact moves only when its museum is full. `CanMoveGreatWork` swaps an artifact only with another artifact in a full museum and never moves it into an empty slot. The state gives `lockedTurns` and `movable` on each work. Where a work can go is the next section.
- **Totals.** `GetBuildingYieldFromGreatWorks(yield, building)` gives a building's yield for each `GameInfo.Yields()` row, and `GetBuildingTourismFromGreatWorks(religious, building)` gives the tourism, once for each value of `religious`. `AddYield` sums them by yield name for the "providing" row.

### The state

The `greatWorks` section holds `slots`, a flat list with the city, building, slot kind, the object types it accepts, the work,
and whether the work counts toward the theme, `buildings` with the theme, its rules and progress, and the yields, and the totals `works`, `spaces`, and `provides`. Tourism is a yield of type `TOURISM` in `provides`.

Screenshots on 2026-11-07 of a game with 31 works and 50 spaces show the rest of what the screen holds, which the section still has to match. 

Broadway and the Sydney Opera House showed Theming(1/3) with every slot empty, with the art museum's bonus text, and showed no label once the slots were filled.

The wonders have no theming. In `PopulateGreatWorkSlot`, an empty building sets the label only when it has a theme text, and never clears it otherwise.

The screen reuses its building boxes, so the empty wonders kept the label of an art museum that used the box before. The state gives them no `theme`, as the filled screen does.

A themed museum shows THEMED and doubles its yields, 9 to 18 in the artifact museum, and a work's tooltip says why it does not fit.

## Method

1. Send `SentientSystemsCore_StateGreatWorks.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4, and send `SentientSystemsCore_State.lua` again so it calls it.
2. Compare the `greatWorks` section with the Great Works screen: the slots and works of each building, the theming label, the two header counts, and the providing row.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`, with 22 buildings, 50 slots, and 38 works. The running game predated the trade and espionage sections, so they were stubbed for the read.

| Check | Result |
| --- | --- |
| The display spaces | 50, the same as the screen's header |
| The theme progress of the 3 art museums and 3 artifact museums | The same as each Theming label: 1 of 3 for most, 2 of 3 for the Bibrax art museum, and 3 of 3 with `complete` true for the themed Con Cuông museum |
| The yields and tourism of each building | The same as the screenshots: 9 and 9 for an artifact museum, 18 and 18 for the themed one, 12 and 12 for the Hermitage, 12 and 20 for Broadway, 12 and 12 for the Sydney Opera House, 6 faith and 8 tourism for the temple |
| The wonders and the palace | No `theme`, as the screen shows no label once they are filled. The palace slot accepts every object type except artifacts |
| The locks | 16 art works with 7 or 9 turns left and `movable` false, as the pop-up said 9 turns for one |
| The size | 23.4 KB for the section |

The header: 38 works, 50 display spaces, and providing 120 culture, 6 faith, and 153 tourism, the same as the section's `works`, `spaces`, and `provides`.

Not yet compared: auto theming, because this game's civilization doesn't have it.

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-07.
