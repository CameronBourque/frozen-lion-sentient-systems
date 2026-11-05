# Research choices

Status: confirmed. The techs and civics the player can research, and the tech and civic trees from `SentientSystems_GetTechTree` and `SentientSystems_GetCivicTree`, the tech tree also with the Tech and Civic Shuffle mode, are confirmed in a running game.

The calls the tech and civic choices and the tech and civic trees use, as the research choosers and the tree screens show them. The other choices are in the [choices index](README.md).

See [design/core/mod/choices.md](../../design/core/mod/choices.md) and [design/core/mod/trees.md](../../design/core/mod/trees.md).

## Questions

None open.

## What we know now

### Techs and civics

`GetData` in `Base/Assets/UI/Choosers/ResearchChooser.lua`, lines 49 to 99, lists each row of `GameInfo.Technologies()` for which `player:GetTechs():CanResearch(index)` is `true`, and the tech in research, from `GetResearchingTech()`, which is -1 for none.

The expansions' replacement, `ResearchChooser_Expansion1.lua`, only adds the research alliance icon. Confirmed in files and on Windows on 2026-10-26.

- **Cost, progress, and turns.** `GetResearchData` in `Base/Assets/UI/TechAndCivicSupport.lua`, lines 536 to 578, reads `GetResearchCost(index)`, `GetResearchProgress(index)`, and `GetTurnsToResearch(index)`. Confirmed in files and on Windows on 2026-10-26.
- **Boost.** A tech has a boost when a row of `GameInfo.Boosts()` has its `TechnologyType`. The row's `Boost` is the percent of the cost, such as 40, and `TriggerDescription` is a text key, such as the one for `Found a city on the Coast.`.

  `HasBoostBeenTriggered(index)` tells whether the boost fired. Confirmed in files and on Windows on 2026-10-26.
- **Recommended.** `player:GetGrandStrategicAI():GetTechRecommendations()` lists the advisor's picks, each with `TechHash`, and the chooser and the tech tree mark them with the advisor's icon. Confirmed in files and on Windows on 2026-10-26.
- **Unlocks.** `PopulateUnlockablesForTech` in `TechAndCivicSupport.lua`, lines 342 to 415, draws an icon for each row of `GetUnlockablesForTech(techType, playerID, items)`, from `Base/Assets/UI/TechAndCivicUnlockables.lua`, whose first field is the type, such as `UNIT_GALLEY`.

  `items` is `GetFilteredUnlockableItems(playerID)`, which is slow to build, so the caller builds it once. `include("TechAndCivicUnlockables")` loads the file in `SentientSystemsCore_UI`.

  The function then draws a star, a special unlock, with the tech's `Description` as its tooltip, at lines 391 to 412. Confirmed in files and on Windows on 2026-10-26.
- **Civics.** `GetData` in `Base/Assets/UI/Choosers/CivicsChooser.lua`, lines 45 to 96, and `GetCivicData` in `TechAndCivicSupport.lua`, lines 653 to 695, work as for techs, with `GameInfo.Civics()` and `player:GetCulture()`.

  The calls are `CanProgress(index)`, `GetProgressingCivic()`, `GetCultureCost(index)`, `GetCulturalProgress(index)`, `GetTurnsToProgressCivic(index)`, and `HasBoostBeenTriggered(index)`.

  A civic's boost is the row of `GameInfo.Boosts()` with its `CivicType`. The advisor's picks come from `GetCivicsRecommendations()`, each with `CivicHash`. `GetUnlockablesForCivic(civicType, playerID)` lists the unlocks, such as `POLICY_AGOGE` and `UNIT_TRADER`, and takes no list of items.

  `PopulateUnlockablesForCivic`, lines 233 to 336, draws a government as a card with its policy slots, and leaves out the civic's star when it shows an icon for an envoy or a governor title. Confirmed in files and on Windows on 2026-10-26.

### Tech and civic trees

`Base/Assets/UI/Screens/TechTree.lua` draws the tech tree. `DLC/Expansion1` adds the research alliance icon, and `DLC/Expansion2` only changes the search. Confirmed in files.

- **Nodes.** `PopulateItemData`, lines 1374 to 1447, builds the nodes from `UITree.GetAvailableTechs()`, which works in `SentientSystemsCore_UI`. Each node has `Name`, the tech's type, `Cost`, `TreeRow`, and `PrereqTechTypes`, the prerequisites the running game has.

  In a game with the Tech and Civic Shuffle mode, they were the shuffled ones, such as `TECH_SAILING` after `TECH_ANIMAL_HUSBANDRY`. `Cost` is the base cost, 25 for Pottery, where `GetResearchCost` gave the player's cost, 12. Confirmed in files and on Windows on 2026-10-26.
- **Status and turns.** `GetCurrentData`, lines 1059 to 1255, gives each node a status: researched when `HasTech(index)` is `true`, current for the tech in research, ready when `CanResearch(index)` is `true`, and blocked otherwise.

  The node in research shows `GetTurnsLeft()`, and the others `GetTurnsToResearch(index)`. `PopulateNode`, lines 778 to 967, shows turns only when they are above 0, and no boost for a researched node. Before the first city, every node's turns were -1. Confirmed in files and on Windows on 2026-10-26.
- **Unrevealed nodes.** With the Tech and Civic Shuffle mode, `IsTechRevealed(index)` is `false` for a node the player can't see yet. `PopulateNode` shows such a node as `LOC_TECH_TREE_NOT_REVEALED_TECH`, `Unrevealed`, with no unlocks or boost.

  Its lines to other nodes still show. On turn 1, 3 of the 77 nodes were revealed: Animal Husbandry, Mining, and Pottery. Without the mode, `IsTechRevealed` returned `true` for every node. Confirmed in files and on Windows on 2026-10-26.
- **Civic tree.** `Base/Assets/UI/Screens/CivicsTree.lua` builds the civic tree the same way, from `UITree.GetAvailableCivics()`, with `HasCivic(index)`, `GetTurnsLeft()`, and `IsCivicRevealed(index)` on `player:GetCulture()`, in `GetCurrentData`, lines 1231 to 1432.

  A civic node holds its type in `CivicName` and its index in `CivicType`, and `PrereqCivicTypes` lists types, as `PopulateItemData`, lines 1566 to 1645, reads them.

  The screen also draws an icon with a number for each envoy or governor title a civic gives, which the civic's row doesn't hold. Confirmed in files and on Windows on 2026-10-26.
- **Timeline.** `GetCurrentData` in `TechTree.lua`, lines 1143 to 1177, reads each major player from `Game.GetPlayers({ Major = true })`, and marks a player the local player has met, with `player:GetDiplomacy():HasMet(id)`, at the column of the latest tech they have researched.

  `HasMet` returned `false` for the player's own ID. Confirmed in files and on Windows on 2026-10-26.

## Method

1. To give the player techs, send `SetTech` as in [choices/production.md](production.md#method), step 2.
2. Read `SentientSystems_GetChoices`, `SentientSystems_GetTechTree`, and `SentientSystems_GetCivicTree` with `npm run state`.

## Results

A single-player game with Gathering Storm, on turn 14, with one city, Rome, at 3 population, in `SentientSystemsCore_UI`:

- **Techs the player could research on turn 15, with Pottery, Masonry, Writing, and Astrology from `SetTech`.** Animal Husbandry and Mining, each 12 cost, 1 turn, and no boost.

  Sailing and Irrigation, each 25 cost and 1 turn, with 40% boosts for `Found a city on the Coast.` and `Farm a resource.`. Currency, 72 cost and 9 turns, with a 40% boost for `Make a [ICON_TradeRoute] Trade Route.`.

  The advisor recommended Animal Husbandry and Irrigation. Each but Currency had a description, such as `Allows Builders to embark.`. No tech was in research. The tech tree showed the same turns, boosts, stars, and advisor icons. The choices were 3,617 bytes.
- **Civics the player could research on turn 15.** Craftsmanship, with a 40% boost for `Improve 3 tiles.` and unlocks `POLICY_ILKUM` and `POLICY_AGOGE`.

  Foreign Trade, with a 40% boost for `Discover a second continent.`, the description `Allows the creation of [ICON_TradeRoute] Trade Routes.`, and unlocks such as `UNIT_TRADER`.

  Each 20 cost and 1 turn, and the advisor recommended both. The civics tree showed the same turns, boosts, and advisor icons, and Foreign Trade's six icons: two policies, the trade route, two war declarations, and the star. The choices were 4,165 bytes.
- **`SentientSystems_GetTechTree` in a new game with the Tech and Civic Shuffle mode.** The game had every other game mode but barbarian clans, and was on turn 1 with no city, read through `npm run state`.

  77 nodes: Animal Husbandry, Mining, and Pottery ready, the other 74 blocked, from `?1` to `?74`, such as `?1` after `TECH_ANIMAL_HUSBANDRY` and `?3` after `?2`.

  No node had turns. The advisor recommended Mining and Pottery. Only the player in `players`, with 0 researched. The tree screen showed the same three nodes and Unrevealed boxes. 6,793 bytes.
- **`SentientSystems_GetTechTree` and `SentientSystems_GetCivicTree` on Rome's save on turn 15, through `npm run state`.** The tech tree had 77 nodes, 4 researched and 5 ready, 22,677 bytes.

  The civic tree had 61 nodes: Code of Laws researched, Craftsmanship and Foreign Trade ready and recommended, and Mysticism and State Workforce blocked with their boosts triggered, progress from the boost, and 1 turn each, as the civics tree showed them.

  20,047 bytes. Egypt, met, had 2 techs and 1 civic.

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
