# Great work move action

Status: in progress. Moving and swapping a great work is confirmed in a running game with Gathering Storm, with the file sent through the tuner. Choosing an artifact is not yet tested.

The game call that the great work move action wraps, with the Lua state it runs in and what the game checks. Where a work can go is in [state/great-works.md](../state/great-works.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

- What does the game do with an artifact that the player chooses? That is the second half of the step.

## What we know now

### Request

`MoveGreatWork` in `Base/Assets/UI/GreatWorksOverview.lua`, lines 872 to 915, sends `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.MOVE_GREAT_WORK, parameters)` when the player drops a work on a slot.

The parameters hold the player in `PARAM_PLAYER_ONE`, the cities in `PARAM_CITY_SRC` and `PARAM_CITY_DEST`, and the building indexes in `PARAM_BUILDING_SRC` and `PARAM_BUILDING_DEST`.

They also hold the work's index in `PARAM_GREAT_WORK_INDEX` and the destination slot in `PARAM_SLOT`. The source slot isn't sent, because the work's index names it. Confirmed in files.

The screen does nothing when the drop is on the slot the work is in. A slot that holds a work swaps the two.

### What the game takes

`UI.CanStartPlayerOperation(playerID, PlayerOperations.MOVE_GREAT_WORK, parameters, false)` returned `true` for every request below, and the game did each one:

- An artifact into a slot of its own partial museum, which `CanMoveWorkAtAll` refuses until the museum is full.
- An art work with 9 turns of lock into an empty art slot of another city.
- An artifact into a music slot.

So the action checks the screen's rules itself, with `CanMoveGreatWork` and `CanMoveWorkAtAll` as in [state/great-works.md](../state/great-works.md#where-a-work-can-move). Confirmed on Windows on 2026-11-10.

### What the request does

1.5 seconds after the request, in `SentientSystemsCore_UI`, `GetGreatWorkInSlot` showed the work in the destination slot. A move into an empty slot left the source empty, and a filled destination gave its work to the source slot. Confirmed on Windows on 2026-11-10.

### City IDs

`PARAM_CITY_SRC` and `PARAM_CITY_DEST` took `city:GetID()`, which is the ID in the state's `city.id`, such as 131073. It isn't the city's position in the player's list. Confirmed on Windows on 2026-11-10.

## Method

1. Send `Scripts/SentientSystemsCore_GreatWorks.lua`, `Scripts/State/SentientSystemsCore_StateGreatWorks.lua`, and `Scripts/Actions/SentientSystemsCore_ActionsGreatWorks.lua` to `SentientSystemsCore_UI`, each without its comments and `include` lines, as in [choices/production.md](../choices/production.md#method), step 4.
2. Call `moveGreatWork` from the bridge. Wait 1.5 seconds, then read `SentientSystems_GetAllGreatWorkSlots(Players[0])`.
3. To see what the game takes, send `UI.RequestPlayerOperation` with a rule-breaking request, and read the slots again.

## Results

A single-player game with Gathering Storm, on a save with 8 cities, 38 works, and a partly filled artifact museum.

| Call | Result |
| --- | --- |
| A writing work to an empty amphitheater slot of another city | `{"ok":true}`. The work was in the new slot, and the old one was empty |
| A writing work to a slot that held another writing work | `{"ok":true}`. The two works traded places |
| An artifact to another slot of a full artifact museum | `{"ok":true}`. The two artifacts traded places |
| A music work to a Sydney Opera House slot that held music | `{"ok":true}` |
| The artifact of the partial museum | `Chalice is an artifact, and its museum isn't full.` |
| A full museum's artifact to an empty slot of the partial museum | `An artifact can't move to an empty slot. It swaps with another artifact in a full museum.` |
| An artifact to a music slot | `That slot takes GREATWORKOBJECT_MUSIC, and Amphora is GREATWORKOBJECT_ARTIFACT.` |
| An art work with 9 turns left | `Spring Morning in the Han Palace is locked for 9 more turns.` |
| A work index the player doesn't have | `You have no great work 99. Use an index from the great works state.` |
| A city the player doesn't have | `You have no slot 0 in BUILDING_SYDNEY_OPERA_HOUSE in city 9. Use a slot from the great works state.` |
| A slot number the building doesn't have | `You have no slot 9 in BUILDING_SYDNEY_OPERA_HOUSE in city 131073. Use a slot from the great works state.` |

The raw requests above, sent without the action, left an artifact in a music slot and a locked art work in a new city. The save was only a test save.

Date checked: game files on 2026-11-10. Running game on Windows on 2026-11-10.
