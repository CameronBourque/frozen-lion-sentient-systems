# Action API: deals and end turn

Add the actions that answer a deal, declare war, and end the turn. Part of [phase 1](README.md).

## Tasks

1. **Deals.** Add `SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)`, which accepts or rejects a deal another player proposes.

   Read the calls from `DiplomacyDealView.lua` and its replacements. Add `respondToDeal` to `src/actions/deals.ts`. Commit: `feat(core): add the deal response action`.
2. **End turn.** Add `SentientSystems_EndTurn(playerID, force)`. Without `force`, it returns the blocker as the reason when one is left. With `force`, it sends the request anyway, as the phase 0 gate did, and the game skips the blockers.

   It sends one request at most per turn. See [ending the turn](../../findings/actions/end-turn.md#ending-the-turn). Add `endTurn` to `src/actions/turn.ts`. Commit: `feat(core): add the end turn action`.
3. **Declare war.** Add `SentientSystems_DeclareWar(playerID, otherPlayerID)`, which the unit actions need because an attack that would start a war returns that as its reason.

   Read the calls from `DeclareWarPopup.lua`: `DiplomacyManager.RequestSession` with `DECLARE_SURPRISE_WAR`, or `UI.RequestPlayerOperation` for a city-state.

   Return a reason when the players are already at war. Add `declareWar` to `src/actions/deals.ts`. Commit: `feat(core): add the declare war action`.

4. **Cinematic popups.** With the wonder built popup open, send a request and the end turn call, and record whether the `CINEMATIC` interface mode stops them. Then make the core mod skip the cinematic popups for an agent player, so no one has to press **Close**.

   Start with `WonderBuiltPopup.lua`, then check the other popups that set the mode. See [ending the turn](../../findings/actions/end-turn.md#questions). Commit: `feat(core): skip the cinematic popups for agent players`.
5. **Secret Society popup.** With the joined popup open, send a request and the end turn call, and record whether the popup stops them. Then make the core mod close the popup for an agent player, so no one has to press **Continue**.

   `DLC/Ethiopia/UI/Additions/SecretSocietyPopup.lua` queues it for the local player only, from the joined and discovered notifications. It sets no interface mode and isn't an end-turn blocker.

   Test it in a save with Secret Societies on. Commit: `feat(core): close the secret society popup for agent players`.
6. **Artifact popup.** After the player chooses an artifact, a popup shows the great work it became. With it open, send a request and the end turn call, and record whether the popup stops them. Then make the core mod close the popup for an agent player, so no one has to press **Close**.

   Start with `GreatWorkShowcase.lua`, and check whether it sets the `CINEMATIC` interface mode or is an end-turn blocker. See [great-works.md](../../findings/actions/great-works.md#artifact-request).

   Test it in a save with an archaeologist digging, as for the artifact action. Commit: `feat(core): close the artifact popup for agent players`.
7. **World Congress popups.** When a session starts, the congress screen opens with **Continue**, then shows the voting screen. It stays open after `voteInCongress` has voted and submitted. After a session, the results screen opens, and an emergency that passed shows its own popup.

   Record whether each one stops a request and the end turn call, and whether **Submit** on the voting screen after the action votes a second time. Then make the core mod close them for an agent player.

   Start with `WorldCongressPopup.lua`, `WorldCongressIntro.lua`, `WorldCongressBetweenTurns.lua`, and `WorldCrisisPopup.lua`, and the `WORLD_CONGRESS_RESULTS` and `EMERGENCY_DECLARED` notifications. See [world-congress.md](../../findings/actions/world-congress.md#popups).

   Test it in a save at a session, as for the vote action. Commit: `feat(core): close the World Congress popups for agent players`.

## Done when

In a running game, each action works once from the bridge. `endTurn` without `force` returns the blocker as its reason while one is left, `respondToDeal` returns a reason when no deal is waiting, and `declareWar` returns a reason for a player already at war.

With an agent as the local player, a wonder that the player completes shows no popup and doesn't hold up the next request. Neither does a Secret Society the player joins, an artifact the player chooses, or a World Congress session, its results, or an emergency it starts.

## Record

- Each request function, its Lua state, and its result, in `findings/actions/end-turn.md`.
- The reasons, in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
