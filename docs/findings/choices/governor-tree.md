# Governor tree

Status: confirmed. The governor tree, `SentientSystems_GetGovernorTree`, is confirmed in the same game, and reads safely since the encoder escapes the percent sign, which crashed the game before. It matches the details panel. Secret Societies are confirmed in the same way, on a game with that mode, and match the panel and its details panel.

The calls the governor tree uses, and the Secret Societies, as the Governors panel and its details panel show them. The governor choice is in [choices/governors.md](governors.md). See [design/core/mod/trees.md](../../design/core/mod/trees.md).

## Questions

None open.

## What we know now

### Governors panel

The panel's files are in [state/governors.md](../state/governors.md#governors-panel).

- **Governor tree.** `GameInfo.GovernorPromotionSets()` lists each governor's promotions, and each row of `GameInfo.GovernorPromotions` has `Level`, `Column`, `BaseAbility`, `Name`, and `Description`. `GameInfo.GovernorPromotionPrereqs()` has 48 rows of `GovernorPromotionType` and `PrereqGovernorPromotion`. The game lists both promotions above Tax Collector as prerequisites, and with Reyna holding only Harbormaster, `CanEarnPromotion` was `true` for Tax Collector and `false` for Renewable Subsidizer and Contractor, so a promotion needs any one of its prerequisites. The panel draws the lines from the promotion's place in the tree, not from this table. The tree held 7 governors, 3 appointed and 4 candidates, with 42 promotions in 14,770 bytes. The text of one promotion holds a curly apostrophe, and 11 hold a percent sign. Confirmed in files and on Windows on 2026-10-27.
- **Printing the tree.** The first attempts to read the tree crashed the game with an access violation, three times. The game's log reads printed text as a printf format, and a `% s` in a promotion's description made it read a pointer that was never passed. See [tuner/commands.md](../tuner/commands.md#what-we-know-now). The JSON encoder now writes `%` as `\u0025`. Confirmed on Windows on 2026-10-27.
- **Secret Societies.** `GameInfo.GovernorsCannotAssign()` has a row with `CannotAssign` of `true` for each society: Owls of Minerva, Hermetic Order, Voidsingers, and Sanguine Pact. Its governor is the society, with the society's name, the title **Secret Society**, and a description, and the panel shows it with no stats and no Assign button, as `AddSecretGovernorShared`, `AddSecretGovernorCandidate`, and `AddSecretGovernorAppointed`, in `GovernorPanel.lua`, lines 244 to 350, draw it. Only a society the player has discovered passes `CanEverAppointGovernor`, which was `true` for Owls of Minerva and `false` for the other three, so the panel and the choice show no others. **Appoint** sends the same `APPOINT_GOVERNOR` and costs a title, which is how the player joins. A joined society is in `GetGovernorList()` with no city, its `IdentityPressure` of 10 and 5 turns to establish, which the panel doesn't show, and the game shows a popup, **Owls of Minerva Joined**, that isn't an end-turn blocker. Each society has 4 promotions, `GOVERNOR_PROMOTION_<SOCIETY>_1` to `_4`, in a chain at levels 0 to 3 and column 1, each following the one before. The base ability, such as Initiation, has no condition. The other three have a row in `GameInfo.GovernorPromotionConditions()` with `HiddenWithoutPrereqs`, which `IsPromotionHidden`, in `GovernorSupport.lua`, lines 127 to 147, applies: they are hidden until the governor holds every promotion they follow, and a candidate holds none. The panel then shows the name `???`, from `LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME`, and "The deeper mysteries have not yet been revealed. We must first demonstrate our commitment.", from `LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION`, and `CreateSecretPromotionTree`, in `GovernorDetailsPanel.lua`, lines 270 to 328, lists them in a column with no requirement lines. The numbered types give nothing away. Each real text says when it unlocks, such as "Unlocked in Medieval Era", so `CanEarnPromotion` was `false` for all four at turn 1. Confirmed in files and on Windows on 2026-10-27.

## Method

1. To read the tree before the `.modinfo` loads its file, send the code as in [choices/production.md](production.md#method), step 4.
2. For a Secret Society, start a game with Secret Societies on, discover one, such as the Owls of Minerva by sending an envoy to a city-state, and join it with **Appoint**, or send the same operation. Opening the Governors panel and closing it clears the governor blocker, so reload the save to see it again. `Players[0]:GetGovernors():SetTitleConsidered(true)` clears it from the UI state.

## Results

A single-player game with Gathering Storm, on turn 48, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The governor tree on turn 48, through the bridge's reader | 7 governors: Pingala, Magnus, and Reyna appointed, and Victor, Amani, Moksha, and Liang as candidates, each with 6 promotions, in 14,770 bytes. Pingala's Curator and Space Initiative, Magnus's Industrialist and Black Marketeer, and Reyna's Harbormaster and Forestry Management were `available`, and the 11 percent signs in the texts came back as `%`. The same read, before the encoder escaped `%`, crashed the game each time |
| Reyna's details panel, against her tree | Her base ability, Land Acquisition, on a bar across the top, then Harbormaster on the left and Forestry Management on the right, Tax Collector below them between dashed lines from both, and Contractor on the left and Renewable Subsidizer on the right below it, with dashed lines from Tax Collector to both. The tree has the same six promotions at levels 0 to 3, columns 1, 0, 2, 1, 0, and 2, with the same text, and both promotions above Tax Collector in its `requires`. The panel also showed 5 turns to establish, loyalty per turn 8, **Established in: Ostia**, and **Governor titles available: 1**, **Spent: 8**, as the state does |
| The state, choice, and tree on turn 1 of a Secret Societies save, before joining | `appoint` held the seven governors and **Owls of Minerva** with `secret` and no loyalty or turns. The tree held Owls of Minerva as a candidate, with Initiation held and three promotions with `hidden`, named `???`, and no other society. 16,170 bytes. The panel showed the **Owls of Minerva**, **Secret Society** card with **Initiation** and three `???`, and its details panel the same text for each, and **Governor titles available: 1** |
| The same after joining | The state held Owls of Minerva with `secret`, only Initiation in `promotions`, and no city, loyalty, or turns, and the titles at 0 and 1 spent. The choice held nothing, as there was no title and nothing to assign. The tree held it as appointed, with Ritual shown with its real text, `locked`, and the next two still `hidden`. 16,181 bytes |

Date checked: game files on 2026-10-27. Running game on Windows on 2026-10-27.
