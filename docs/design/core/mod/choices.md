# Core mod choices

The calls that list the legal options for each choice, and the tiles where a district or a wonder can go. Part of the [core mod](README.md).

## Choices

`SentientSystems_GetChoices(playerID)` returns the legal options for each discrete choice as JSON, in a call of its own, so the agent reads them only when it decides.

The options include production and gold, faith, and tile purchases for each city, techs, civics, policies, the destinations of each idle trader, and the options for each other end-turn blocker. Each blocker in the state names the choice that resolves it.

An option lists what its screen shows, such as turns to complete, boost status or the boost requirement, resource requirements, and prerequisites. Tile purchases list the tiles to buy, and the tiles where a district or a wonder can go come from the [placement call](#placement).

An item the screen greys out is listed with the screen's reason, in the game's language, and with its text key where the game gives one.

### Files

`SentientSystems_GetChoices` is in `Scripts/Choices/SentientSystemsCore_Choices.lua`, which the UI script loads with `include`, and the bridge reads it through the stash.

Each choice has its own file in `Scripts/Choices/`, such as `SentientSystemsCore_ChoicesProduction.lua`, which defines one global, such as `SentientSystems_GetProductionChoices(player)`. The choices file loads each one and puts them together.

The production choice counts the tiles from the placement file to decide what the panel greys out. The shape of each choice is in the schemas in [packages/core/bridge/src/choices/](../../../../packages/core/bridge/src/choices/).

### Findings

The calls for each choice are in these findings:

- **Units, buildings, wonders, and projects.** [findings/choices/production.md](../../../findings/choices/production.md).
- **Districts.** [findings/choices/districts.md](../../../findings/choices/districts.md).
- **Purchases.** [findings/choices/purchases.md](../../../findings/choices/purchases.md).
- **Techs and civics.** [findings/choices/research.md](../../../findings/choices/research.md).
- **Government and policies.** [findings/choices/government.md](../../../findings/choices/government.md).
- **Religion.** [findings/choices/religion.md](../../../findings/choices/religion.md).
- **Envoys.** [findings/choices/city-states.md](../../../findings/choices/city-states.md).
- **Great people.** [findings/choices/great-people.md](../../../findings/choices/great-people.md).
- **Captured cities.** [findings/choices/captured-cities.md](../../../findings/choices/captured-cities.md).
- **Spies.** [findings/choices/spies.md](../../../findings/choices/spies.md).
- **Spy missions.** [findings/choices/spy-missions.md](../../../findings/choices/spy-missions.md).
- **Trade routes.** [findings/choices/trade-routes.md](../../../findings/choices/trade-routes.md).
- **Artifacts.** [findings/choices/artifacts.md](../../../findings/choices/artifacts.md).
- **Governors.** [findings/choices/governors.md](../../../findings/choices/governors.md).
- **Dedications.** [findings/choices/dedications.md](../../../findings/choices/dedications.md).
- **Emergencies.** [findings/choices/emergencies.md](../../../findings/choices/emergencies.md).
- **World Congress.** [findings/choices/world-congress.md](../../../findings/choices/world-congress.md).

## Placement

`SentientSystems_GetPlacement(playerID, cityID, type)` in `Scripts/Placement/SentientSystemsCore_Placement.lua` returns where a city can place one district or wonder as JSON. It is a call of its own, as the placement view shows the tiles once the player picks one.

The UI script loads the file, and the bridge reads the call through the stash. It raises an error for an ID with no player or city, and for a type that isn't a district or a wonder.

The calls are in [findings/choices/placement.md](../../../findings/choices/placement.md). The shape is in [packages/core/bridge/src/placement/](../../../../packages/core/bridge/src/placement/).

## Decisions

| Decision | Reason |
| --- | --- |
| The choices list the legal options for discrete choices, and the placement call the tiles for a district or a wonder | Saves wasted calls. Those tiles are few, so a list beats guessing. Moves and attacks have too many targets to list, so they return failure reasons instead |
| The tiles for districts and wonders are a call of their own, for one district or wonder | Tiles were about two thirds of the production choice, and a mid-game empire would send about 100 KB of them. The agent needs the tiles only for the one item it places |
| The choices are a call of their own, not part of the state | Production options for every city are large, and the agent needs them only when it decides. Keeping them out of the state keeps each turn's context small |
| A greyed-out option carries the screen's own text | It needs no upkeep and matches what a player reads. Our own codes would need a mapping for every reason, including those from DLC and mods. If agents misread the text, codes come next |
