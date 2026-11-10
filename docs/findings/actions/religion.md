# Religion actions

Status: confirmed. Founding a pantheon, and founding a religion with a custom name and its beliefs, are confirmed in a running game with Gathering Storm.

The game calls that the pantheon and religion actions wrap, with the Lua state they run in and what the game checks. The beliefs and religions the player can pick are in [choices/religion.md](../choices/religion.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Pantheon

`ConfirmPantheon` in `Base/Assets/UI/Choosers/PantheonChooser.lua` calls `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.FOUND_PANTHEON, parameters)`. The parameters hold the belief's hash in `PARAM_BELIEF_TYPE` and `VALUE_EXCLUSIVE` in `PARAM_INSERT_MODE`. Confirmed in files.

- The chooser checks nothing before its request, because it lists only the beliefs `CanSelectBelief` allows. Confirmed in files.
- `UI.CanStartPlayerOperation(playerID, PlayerOperations.FOUND_PANTHEON, parameters, testOnly)` returned `true` with no reasons for a pantheon belief and for a follower belief, with `testOnly` `true` and `false`. So the action checks the class itself. Confirmed on Windows on 2026-11-09.
- The request runs in `SentientSystemsCore_UI`. 1.5 seconds after it, `GetPantheon()` returned the belief's index, `CanCreatePantheon()` returned `false`, and the faith balance had dropped by `GetMinimumFaithNextPantheon()`. Confirmed on Windows on 2026-11-09.
- Once the pantheon is founded, `IsInSomePantheon` is `true` for its belief, and `ENDTURN_BLOCKING_PANTHEON` leaves the blockers. Confirmed on Windows on 2026-11-09.

### Religion

`ConfirmReligionBeliefs` in `Base/Assets/UI/ReligionScreen.lua` sends two kinds of request on one click, each with `UI.RequestPlayerOperation(Game.GetLocalPlayer(), operation, parameters)`. Confirmed in files.

1. `PlayerOperations.FOUND_RELIGION`, with the religion's hash in `PARAM_RELIGION_TYPE` and `VALUE_EXCLUSIVE` in `PARAM_INSERT_MODE`. For a religion with `RequiresCustomName`, it adds the text of the name box in `PARAM_RELIGION_CUSTOM_NAME`.
2. `PlayerOperations.ADD_BELIEF` for each belief picked, with the belief's hash in `PARAM_BELIEF_TYPE` and `VALUE_EXCLUSIVE` in `PARAM_INSERT_MODE`.

What the screen allows before its click, all confirmed in files:

- **Name.** The name box takes a name only when the game has `CAPABILITY_RENAME`. Otherwise it holds the religion's own name, `Locale.Lookup(row.Name)`. `IsReligionNameValid` refuses a name that is empty or only spaces.
- **Beliefs.** `SelectReligionBeliefs` lists only follower beliefs for the first pick of a new religion. `PopulateAvailableBeliefs` then leaves out each class already picked.

  `OnBeliefSelected` goes to the confirm once the picks reach `GetNumBeliefsEarned()` less the beliefs the religion has.

What the game takes and does:

- `UI.CanStartPlayerOperation(playerID, operation, parameters, false)` returned `true` for `ADD_BELIEF` with a pantheon belief, and with a worship belief as the first belief.

  It also returned `true` for `FOUND_RELIGION` with `RELIGION_CUSTOM_1` and no name, and with the pantheon row. So the action checks the screen's rules itself. Confirmed on Windows on 2026-11-09.
- 1.5 seconds after the requests, `GetReligionTypeCreated()` returned the religion's index, `Game.GetReligion():GetName(index)` returned the custom name, and the religion held both beliefs. Confirmed on Windows on 2026-11-09.
- After the prophet's `UNITOPERATION_FOUND_RELIGION`, `GetNumBeliefsEarned()` went from 0 to 2. `HasReligiousFoundingUnit()` stayed `true` on that turn, before and after the religion was founded. Confirmed on Windows on 2026-11-09.

## Method

1. To get the pantheon blocker, follow [choices/religion.md](../choices/religion.md#method), step 2.
2. Send `Scripts/SentientSystemsCore_Religion.lua`, then `Scripts/Actions/SentientSystemsCore_ActionsReligion.lua`, to `SentientSystemsCore_UI`, as in [choices/production.md](../choices/production.md#method), step 4.
3. Call `foundPantheon` from the bridge. Wait 1.5 seconds, then read `GetPantheon()`, `CanCreatePantheon()`, and `GetFaithBalance()` on `Players[0]:GetReligion()`.
4. To see what the game takes, call `UI.CanStartPlayerOperation` with the pantheon chooser's parameters and a belief of another class.
5. To found a religion, get a Great Prophet with `patronizeGreatPerson`, as in [great-people-screen.md](great-people-screen.md#method). A prophet that appeared this turn has no moves.

   In `GameCore_Tuner`, send `UnitManager.PlaceUnit(unit, x, y)` to put it on a Holy Site, then `UnitManager.RestoreMovement(unit)`.
6. Activate the prophet with `unitAction` and `found_religion`. Then call `foundReligion` from the bridge, wait 1.5 seconds, and read `Game.GetReligion():GetReligions()`.

## Results

A single-player game with Gathering Storm, on Rome's save on turn 15, in `SentientSystemsCore_UI`, for player 0, with 1,004 faith and a pantheon cost of 12:

| Call | Result |
| --- | --- |
| `foundPantheon(BELIEF_NOPE)` | `BELIEF_NOPE isn't a belief.`, and a pointer to the choice |
| `foundPantheon(BELIEF_FEED_THE_WORLD)` | `BELIEF_FEED_THE_WORLD isn't a pantheon belief.`, and a pointer to the choice |
| `foundPantheon(BELIEF_RELIGIOUS_SETTLEMENTS)` | `{"ok":true}`. The pantheon became Religious Settlements, index 19, and the faith 992 |
| `foundPantheon(BELIEF_GOD_OF_THE_SEA)`, after that | `You have a pantheon already, BELIEF_RELIGIOUS_SETTLEMENTS.` |

After the pantheon, the state showed `"pantheon":"BELIEF_RELIGIOUS_SETTLEMENTS"`, and `ENDTURN_BLOCKING_UNITS` was the only blocker.

The same save on turn 15, with a Great Prophet from faith patronage and `CAPABILITY_RENAME` on:

| Call | Result |
| --- | --- |
| `foundReligion(RELIGION_BUDDHISM, [FEED_THE_WORLD, GURDWARA])`, with the prophet in Rome | `Activate your Great Prophet on a Holy Site first, with the found_religion order.` |
| `foundReligion(RELIGION_BUDDHISM, [GURDWARA, FEED_THE_WORLD])`, after the prophet founded on the Holy Site | `A new religion's first belief is a follower belief, ...` |
| `foundReligion(RELIGION_BUDDHISM, [FEED_THE_WORLD, CHORAL_MUSIC])` | `Pick one belief of each class. ...` |
| `foundReligion(RELIGION_BUDDHISM, [FEED_THE_WORLD])` | `Pick 2 beliefs, as the religion choice's picks says.` |
| `foundReligion(RELIGION_BUDDHISM, [FEED_THE_WORLD, GOD_OF_THE_SEA])` | `BELIEF_GOD_OF_THE_SEA is a pantheon belief. ...` |
| `foundReligion(RELIGION_CUSTOM_1, [FEED_THE_WORLD, GURDWARA])`, with no name | `RELIGION_CUSTOM_1 needs a name. Give one.` |
| `foundReligion(RELIGION_BUDDHISM, [FEED_THE_WORLD, GURDWARA], "Lion")` | `RELIGION_BUDDHISM has a fixed name. Leave out the name.` |
| `foundReligion(RELIGION_CUSTOM_1, [FEED_THE_WORLD, GURDWARA], "Way of the Lion")` | `{"ok":true}`. The religion, index 13, was named Way of the Lion, with both beliefs |
| `foundReligion(RELIGION_BUDDHISM, [CHORAL_MUSIC, TITHE])`, after that | `You have founded RELIGION_CUSTOM_1 already.` |

After the religion, the state's `founded` showed `RELIGION_CUSTOM_1`, Way of the Lion, both beliefs, and Rome as the holy city.

Date checked: 2026-11-09.
