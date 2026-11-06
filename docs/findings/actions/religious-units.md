# Religious unit actions

Status: open. Founding a religion, spreading it, removing a heresy, and healing are confirmed in a running game with Gathering Storm, with the files sent through the tuner. Condemning a heretic is confirmed in files only.

The game calls the religious unit orders wrap, with the Lua state each runs in and the reasons their checks give. The religion itself, its name and beliefs, is chosen in the religion blocker's action, which a later step adds.

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other unit actions are in the [actions index](README.md).

## Questions

1. Does `condemn_heretic` work? Any unit can take it against a religious unit of another religion, as the player reports, so the action doesn't limit it by kind. Its check was `false` for every unit seen, and no player was at war with the player, so the request is untested.

## What we know now

### Operations

`UnitPanel.lua` has no code for these. They are plain unit operations, and one command, that its loop checks loosely and then for real and requests with no parameters. Confirmed in files.

- **Found a religion.** `UNITOPERATION_FOUND_RELIGION`, for a unit whose `GameInfo.Units` row has `FoundReligion`, which is the Great Prophet. The real check's reason says where: "Must be on your Holy Site district or Stonehenge wonder."

  The request uses up the prophet. The player then names the religion and picks its beliefs on the religion screen, whose confirmation is `UI.RequestPlayerOperation(player, PlayerOperations.FOUND_RELIGION, parameters)` in `ReligionScreen.lua`. Confirmed in files.
- **Spread.** `UNITOPERATION_SPREAD_RELIGION`, for a row with `SpreadCharges` above zero: the Missionary, the Apostle, and the Inquisitor. The loose check fails with the tile, so the kind of unit comes from the row.
- **Remove heresy.** `UNITOPERATION_REMOVE_HERESY`, for a row with `RequiresInquisition`, the Inquisitor. It uses the spread icon, and in a city of the player's religion the Inquisitor's spread check is `false` while this one is `true`.
- **Heal.** `UNITOPERATION_RELIGIOUS_HEAL`, for a row with `ReligiousHealCharges` above zero, which is the Guru.

  It heals the religious units on the Guru's tile and the tiles next to it, itself included. A wounded Knight on the tile didn't count, and a wounded Apostle did. Religious units can't stack, so a wounded Guru heals itself, since it is the one religious unit on its tile.
- **Condemn.** `UNITCOMMAND_CONDEMN_HERETIC` has three reasons in the text.

  A religious unit on the tile belongs to a player the unit is not at war with, adheres to the religion the player founded, or adheres to the dominant religion in most of the player's cities.
- A unit's religion matters. A Missionary made by `UnitManager.InitUnit` has no religion, and spread was refused.

  One bought with faith in the holy city has the religion.

## Method

1. Send the files' code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_UnitAction(playerID, unitID, "found_religion")`, `"spread_religion"`, `"heal_followers"`, or `"condemn_heretic"`.
2. To get a unit with the religion, buy it with faith in `SentientSystemsCore_UI`: `CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, params)`.

   `PARAM_UNIT_TYPE` is the unit's hash, `PARAM_MILITARY_FORMATION_TYPE` the standard formation, and `PARAM_YIELD_TYPE` faith. `CityManager.CanStartCommand` with the same parameters says whether the city may.
3. An Apostle, a Guru, or an Inquisitor needs a Temple in the city, and an Inquisitor needs an Apostle's launch of the inquisition first.

   A purchased unit needs a free tile in the city center or its districts, so a city whose two tiles each hold a unit can't buy another.

## Results

A single-player game on turn 403, on Windows, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| A Great Prophet next to the Holy Site, for `found_religion` | The reason said the unit was skipping its turn, then to wake it first |
| The same prophet moved onto the Holy Site with `SentientSystems_MoveUnit`, for `found_religion` | `{"ok":true}`. The prophet was gone, and the player founded Catholicism on the religion screen |
| A Missionary made by `InitUnit`, in Rome | `false` for the check. Its `GetReligionType()` was -1 |
| A Missionary bought with faith in Ravenna, the holy city, moved to Rome, for `spread_religion` | `{"ok":true}`, and its spread charges went from 3 to 2 |
| A Guru made by `InitUnit`, for `heal_followers` | The loose check was `true` on a tile with a Knight and `false` elsewhere, and the real check was `false`. The Guru has no religion |
| A Guru bought with faith, next to and then with a wounded Knight, for `heal_followers` | Refused, with no reason from the game. The loose check was `false` on another tile and `true` on the Knight's, the real check `false` |
| The same Guru on the tile of a wounded Apostle with the religion, 40 damage | `{"ok":true}`, and the Apostle's damage went to 0 |
| An Inquisitor, in Ravenna where the player's religion is the majority, for `spread_religion` and `remove_heresy` | `spread_religion` was refused. `remove_heresy` returned `{"ok":true}`, and its charges went from 3 to 2. The effect on the city's other religions was not read |
| An `InitUnit` Apostle, for `condemn_heretic` | Refused with no reason from the game. The action says what it needs |
| An Apostle, for the inquisition and Evangelize Belief | Both checks were `true`. The actions are not part of this step |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
