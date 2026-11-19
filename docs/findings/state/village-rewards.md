# Village rewards

Status: confirmed. The reward event of a tribal village and of a meteor site is confirmed in a running game on Windows.

The game event that reports what a tribal village or a Gathering Storm meteor site gave, and the text the game has for each reward. The events section of the state keeps it, as [design/core/mod/state.md](../../design/core/mod/state.md#files) says.

## Questions

None open.

## What we know now

`Events.GoodyHutReward(playerID, unitID, typeHash, subTypeHash)` fires once when a unit enters a tribal village or a meteor site, after the reward is given. Confirmed on Windows on 2026-11-19.

- Both hashes are `DB.MakeHash` of a name: `typeHash` of the row's `GoodyHutType`, such as `GOODYHUT_GOLD`, and `subTypeHash` of the sub-type's `SubTypeGoodyHut`, such as `GOODYHUT_SMALL_GOLD`.
- `GameInfo.GoodyHutSubTypes` has no `Hash` column. In `GameInfo.GoodyHuts`, `GOODYHUT_GOLD` has a `Hash` equal to its `DB.MakeHash`, and `METEOR_GOODIES` has none.
- A meteor site is the improvement `IMPROVEMENT_METEOR_GOODY`, with the reward type `METEOR_GOODIES`.
- No UI Lua file builds the floating text the game shows over the tile. Only `TutorialUIRoot.lua` listens to the event, and it reads no argument. Confirmed in files.

Of the 25 sub-types, 6 have a `Description` with text in English, and each is wrapped in a color tag. The rest, such as the gold, faith, relic, boost, population, builder, trader, settler, envoy, and resource rewards, have a key with no text or no key. Confirmed on Windows on 2026-11-19.

The amount of a reward isn't the modifier's: the small gold reward's modifier gives an `Amount` of 40, and the player gained 20. The amounts scale with the game, so the state's own values show what a reward added.

## Method

1. Load a save with a unit next to a tribal village, and add a listener to `Events.GoodyHutReward` in `SentientSystemsCore_UI` that records every argument.
2. Move the unit into the village, and read the player's gold and faith before and after.
3. For a meteor site, place `IMPROVEMENT_METEOR_GOODY` next to the unit with `ImprovementBuilder.SetImprovementType(plot, index, -1)` in `GameCore_Tuner`, and move the unit onto it.
4. Match the hashes to the rows of `GameInfo.GoodyHuts` and to `DB.MakeHash` of each sub-type's name, and print `Locale.Lookup` of each sub-type's `Description`.

## Results

- **A scout entering the village at (15, 7) on turn 8 of the Claude Code gate game.** One call with player 0, the scout's ID, `-2010932837`, and `-856816033`. Gold went from 43 to 63, and the scout gained 7 experience. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The scout entering a meteor site placed at (14, 7), on turn 9.** One call with player 0, the scout's ID, `-293282370`, and `1419298788`, which are `DB.MakeHash` of `METEOR_GOODIES` and `METEOR_GRANT_GOODIES`.

  The events held "A meteor site at (14, 7) gave meteor grant goodies. Free military unit!" Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The hashes.** `-2010932837` is the `Hash` of `GOODYHUT_GOLD`, and `-856816033` is `DB.MakeHash("GOODYHUT_SMALL_GOLD")`. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The descriptions of the 25 sub-types.** Text for the scout, upgrade, experience, heal, free technology, and governor title rewards, and for `METEOR_GRANT_GOODIES`. Empty or no key for the rest. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **`ModifierArguments` of `GOODY_GOLD_SMALL_MODIFIER`.** `Amount` 40, `YieldType` `YIELD_GOLD`, and `Scale` 1. Run in `SentientSystemsCore_UI` on 2026-11-19.

Date checked: game files on 2026-11-19, and running game on Windows on 2026-11-19.
