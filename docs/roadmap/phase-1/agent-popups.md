# Popups for agent players

Make the core mod close or skip the popups and screens that wait for a click, so an agent player is never held up by a screen it can't see. Part of [phase 1](README.md).

Each task first records whether its popup stops a request and the end turn call, which needs the end turn action from [deals and end turn](action-api-deals-and-end-turn.md).

## Tasks

1. **Cinematic popups.** With the wonder built popup open, send a request and the end turn call, and record whether the `CINEMATIC` interface mode stops them. Then make the core mod skip the cinematic popups for an agent player, so no one has to press **Close**.

   Start with `WonderBuiltPopup.lua`, then check the other popups that set the mode. See [ending the turn](../../findings/actions/end-turn.md#questions). Commit: `feat(core): skip the cinematic popups for agent players`.
2. **Natural disaster popups.** With the popup for a flood, a drought, a storm, an eruption, or another weather event open, send a request and the end turn call, and record whether it stops them. Then make the core mod skip it for an agent player, as for the cinematic popups.

   `DLC/Expansion2/UI/Additions/NaturalDisasterPopup.lua` sets the `CINEMATIC` interface mode when it opens and `SELECTION` when it closes, as the wonder popup does.

   Test it in a Gathering Storm save with the disaster intensity raised. Commit: `feat(core): skip the natural disaster popups for agent players`.
3. **Secret Society popup.** With the joined popup open, send a request and the end turn call, and record whether the popup stops them. Then make the core mod close the popup for an agent player, so no one has to press **Continue**.

   `DLC/Ethiopia/UI/Additions/SecretSocietyPopup.lua` queues it for the local player only, from the joined and discovered notifications. It sets no interface mode and isn't an end-turn blocker.

   Test it in a save with Secret Societies on. Commit: `feat(core): close the secret society popup for agent players`.
4. **Artifact popup.** After the player chooses an artifact, a popup shows the great work it became. With it open, send a request and the end turn call, and record whether the popup stops them. Then make the core mod close the popup for an agent player, so no one has to press **Close**.

   Start with `GreatWorkShowcase.lua`, and check whether it sets the `CINEMATIC` interface mode or is an end-turn blocker. See [great-works.md](../../findings/actions/great-works.md#artifact-request).

   Test it in a save with an archaeologist digging, as for the artifact action. Commit: `feat(core): close the artifact popup for agent players`.
5. **World Congress popups.** When a session starts, the congress screen opens with **Continue**, then shows the voting screen. It stays open after `voteInCongress` has voted and submitted. After a session, the results screen opens, and an emergency that passed shows its own popup.

   Record whether each one stops a request and the end turn call. **Submit** on the voting screen after the action replaces the action's votes and keeps the Favor it spent, so close it before a player can press it. Then make the core mod close them for an agent player.

   Start with `WorldCongressPopup.lua`, `WorldCongressIntro.lua`, `WorldCongressBetweenTurns.lua`, and `WorldCrisisPopup.lua`, and the `WORLD_CONGRESS_RESULTS` and `EMERGENCY_DECLARED` notifications. See [world-congress.md](../../findings/actions/world-congress.md#popups).

   Test it in a save at a session, as for the vote action. Commit: `feat(core): close the World Congress popups for agent players`.

6. **Leader screen.** A war that `declareWar` declares on a major civ, and a peace that `proposePeace` makes, leave the leader screen open on the overview, and no timing of the session close closes it.

   Find a way to keep the leader screen from opening for an agent player, or to close it cleanly, and check whether the open screen stops a request and the end turn call.

   Start with `DiplomacyActionView.lua` and the question in [the leader screen](../../findings/actions/war-and-peace.md#the-leader-screen). Avoid replacing `DiplomacyActionView.lua`, which Gathering Storm and other mods replace.

   Test it with `declareWar` on a major civ, and with the sessions from [diplomacy sessions](diplomacy-sessions.md). Commit: `feat(core): close the leader screen for agent players`.

## Done when

With an agent as the local player, a wonder that the player completes and a natural disaster show no popup and don't hold up the next request.

Neither does a Secret Society the player joins, an artifact the player chooses, or a World Congress session, its results, or an emergency it starts. A war the agent declares leaves no leader screen open.

## Record

- What each popup does to a request and the end turn call, and how the core mod closes it, in [findings/actions/end-turn.md](../../findings/actions/end-turn.md). The leader screen, in [findings/actions/war-and-peace.md](../../findings/actions/war-and-peace.md).
- How the core mod handles popups for an agent player, in [design/core/mod/README.md](../../design/core/mod/README.md).
