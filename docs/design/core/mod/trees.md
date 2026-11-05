# Core mod trees

The calls that return the tech, civic, and governor trees. Part of the [core mod](README.md).

## Tech and civic trees

`SentientSystems_GetTechTree(playerID)` in `Scripts/Trees/SentientSystemsCore_TreesResearch.lua` returns the tech tree as the tree screen shows it, as JSON. It is a call of its own, so the agent reads it only when it plans a route.

The UI script loads the file, and the bridge reads the call through the stash. It reads the tree from the running game, because the Tech and Civic Shuffle mode changes it. The details of each node come from the same reader as the tech choice.

`SentientSystems_GetCivicTree(playerID)` in the same file returns the civic tree in the same form, with `researched` counting civics. The civic tree leaves out the screen's extra icons for envoys and governor titles.

The calls are in [findings/choices/choices.md](../../../findings/choices/choices.md). The shape is in [packages/core/bridge/src/trees/research.ts](../../../../packages/core/bridge/src/trees/research.ts).

## Governor tree

`SentientSystems_GetGovernorTree(playerID)` in `Scripts/Trees/SentientSystemsCore_TreesGovernors.lua` returns the governors and their promotion trees as the Governors panel and its details panel show them, as JSON.

It is a call of its own, so the agent reads it only when it chooses a governor to appoint or a promotion to give. The UI script loads the file, and the bridge reads the call through the stash.

It includes the Secret Societies the player has discovered, and leaves out the governors the player could never appoint. Like the state, it is empty without Rise and Fall.

The calls are in [findings/state/governors.md](../../../findings/state/governors.md). The shape is in [packages/core/bridge/src/trees/governors.ts](../../../../packages/core/bridge/src/trees/governors.ts).

## Decisions

| Decision | Reason |
| --- | --- |
| The trees are calls of their own, built from the running game | The agent reads a tree only when it plans a route. The Tech and Civic Shuffle mode changes the tree, so static data can be wrong |
