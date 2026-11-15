# Popups for agent players

Make the core mod close or skip the popups and screens that wait for a click, so an agent player is never held up by a screen it can't see. Part of [phase 1](README.md).

Each task first records whether its popup stops a request and the end turn call, with `endTurn` from `src/actions/turn.ts`. With `force`, it ends the turn while a blocker is left. See [design/core/mod/actions/turn.md](../../design/core/mod/actions/turn.md).

## Tasks

1. **Cinematic popups.** With the wonder built popup open, send a request and the end turn call, and record whether the `CINEMATIC` interface mode stops them. Then make the core mod skip the cinematic popups for an agent player, so no one has to press **Close**.

   Start with `WonderBuiltPopup.lua`, then check the other popups that set the mode. See [ending the turn](../../findings/actions/end-turn.md#questions). Commit: `feat(core): skip the cinematic popups for agent players`.

2. **Natural disaster popups.** With the popup for a flood, a drought, a storm, an eruption, or another weather event open, send a request and the end turn call, and record whether it stops them. Then make the core mod skip it for an agent player, as for the cinematic popups.

   `DLC/Expansion2/UI/Additions/NaturalDisasterPopup.lua` sets the `CINEMATIC` interface mode when it opens and `SELECTION` when it closes, as the wonder popup does.

   Test it in a Gathering Storm save with the disaster intensity raised. Commit: `feat(core): skip the natural disaster popups for agent players`.

3. **Tech, civic, and boost popups.** A popup shows each tech and civic the player completes, and each boost, and waits for **Close** or **Continue**. Neither holds anything, but each keeps the player from the pause menu.

   Make the core mod turn them off for an agent player with `LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups()`, as the tutorial does, when each load ends. See [popups.md](../../findings/actions/plain-popups.md#tech-civic-and-boost-popups).

   Test it in a save with a tech, a civic, and a boost a turn away. Commit: `feat(core): turn off the tech and civic popups for agent players`.

4. **Secret Society and hero popups.** A popup shows each Secret Society the player discovers or joins, and each hero the player discovers in the Heroes and Legends mode, and waits for **Continue**.

   Neither holds anything, so the turn goes on, but each keeps the player from the pause menu. Make the core mod close both for an agent player.

   `DLC/Ethiopia/UI/Additions/SecretSocietyPopup.lua` and `DLC/Babylon/UI/Additions/HeroesPopup.lua` open by themselves from their notifications, with a plain `UIManager:QueuePopup`.

   Each `Close` is only `UIManager:DequeuePopup`, and neither fires an event of its own. They open from notifications at any time, so the core mod dequeues each one in the popup queue when a batch of game events or a load ends. See [popups.md](../../findings/actions/plain-popups.md#secret-society-and-hero-popups).

   Test it in a save with either mode on. Commit: `feat(core): close the secret society and hero popups for agent players`.

5. **Natural wonder popup.** When the player first sees a natural wonder, a popup shows it and waits for **Close**. It holds the engine's event queue as the wonder built popup does, and held the start of a turn. Then make the core mod close it for an agent player, as for the cinematic popups.

   `Base/Assets/UI/Popups/NaturalWonderPopup.lua` fires `LuaEvents.NaturalWonderPopup_Shown` right after its lock. See [popups.md](../../findings/actions/popups.md#natural-wonder-popup), which has the steps of its `Close` and a live close.

   Test it in a save with a unit one move from an unseen natural wonder. Commit: `feat(core): close the natural wonder popup for agent players`.

6. **Historic moment popups.** In Rise and Fall, a popup shows some of the historic moments that earn the player era score. It doesn't keep the player from the pause menu, but it waits for **Close**.

   Record whether it stops a request and the end turn call, then make the core mod close it for an agent player.

   `DLC/Expansion2/UI/Additions/HistoricMoments.lua` queues itself with `UIManager:QueuePopup`, so the core mod closes it with the hero and Secret Society popups, and also on `Events.UIIdle`. It sends `LuaEvents.HistoricMoments_Closed` after, for the launch bar. See [plain-popups.md](../../findings/actions/plain-popups.md#historic-moment-popup).

   Test it in a save a turn from a historic moment, such as a first to build a wonder or meet a civ. Commit: `feat(core): close the historic moment popups for agent players`.

7. **Era popups.** When a new era starts, a popup shows it, then the era review popup shows the age the player earned, golden, normal, or dark, before the dedication choice. Record whether each one stops a request and the end turn call, then make the core mod close both for an agent player.

   `DLC/Expansion2/UI/Additions/EraCompletePopup.lua` locks, then closes itself when its animation ends, so it needs nothing. `EraReviewPopup.lua` queues itself with `UIManager:QueuePopup`, so the core mod closes it with the other plain popups.

   Its **Continue** opens the dedication popup, which the dedication action doesn't need. See [plain-popups.md](../../findings/actions/plain-popups.md#era-popups).

   Check that the [dedication action](../../design/core/mod/actions/dedications.md) still works with the review popup closed. Test it in a save a turn from a new era. Commit: `feat(core): close the era popups for agent players`.

8. **Great work popup.** A popup shows each great work the player creates, such as an artifact, a painting, or a relic, and waits for **Close**. It holds nothing.

   `Base/Assets/UI/GreatWorkShowcase.lua` shows by unhiding its context, not through the popup queue, so the core mod hides it with the other plain popups and plays its stop sounds. See [plain-popups.md](../../findings/actions/plain-popups.md#great-work-popup).

   Test it with a great writer, artist, or musician's `activate` order, or an archaeologist's dig. Commit: `feat(core): close the great work popup for agent players`.

9. **World Congress popups.** When a session starts, the congress screen opens with **Continue**, then shows the voting screen. It stays open after `voteInCongress` has voted and submitted. After a session, the results screen opens, and an emergency that passed shows its own popup.

   Record whether each one stops a request and the end turn call. **Submit** on the voting screen after the action replaces the action's votes and keeps the Favor it spent, so close it before a player can press it. Then make the core mod close them for an agent player.

   Start with `WorldCongressPopup.lua`, `WorldCongressIntro.lua`, `WorldCongressBetweenTurns.lua`, and `WorldCrisisPopup.lua`, and the `WORLD_CONGRESS_RESULTS` and `EMERGENCY_DECLARED` notifications. See [world-congress.md](../../findings/actions/world-congress.md#popups).

   Test it in a save at a session, as for the vote action. Commit: `feat(core): close the World Congress popups for agent players`.

10. **Leader screen.** A war that `declareWar` declares on a major civ, and a peace that `proposePeace` makes, leave the leader screen open on the overview, and no timing of the session close closes it.

    Find a way to keep the leader screen from opening for an agent player, or to close it cleanly, and check whether the open screen stops a request and the end turn call.

    Start with `DiplomacyActionView.lua` and the question in [the leader screen](../../findings/actions/war-and-peace.md#the-leader-screen). Avoid replacing `DiplomacyActionView.lua`, which Gathering Storm and other mods replace.

    Test it with `declareWar` on a major civ, and with the sessions in [AI diplomacy sessions](../../findings/actions/ai-sessions.md). The goodbye closing passed with `declareWar` on the Maori on 2026-11-13. Commit: `feat(core): close the leader screen for agent players`.

    Closing the goodbye from a listener on `Events.DiplomacyStatement` left no leader screen after `SentientSystems_DeclareWar`. See [closing a goodbye](../../findings/actions/ai-sessions.md#closing-a-goodbye). Check whether that answers this task.

11. **Unit captured popup.** When a unit of the player's is captured, or the player captures one, a popup names the other civ and waits for **OK**. Record whether it stops a request and the end turn call. Then make the core mod close it for an agent player, and pass its text to the agent.

    `Base/Assets/UI/Popups/UnitCaptured.lua` opens it from `Events.UnitCaptured`, for the local player only, and only in single player. Commit: `feat(core): close the unit captured popup for agent players`.

12. **Spy mission popup.** When a spy's mission ends, a popup shows the result. Record whether it stops a request and the end turn call. Then make the core mod close it for an agent player, and pass the result to the agent.

    `Base/Assets/UI/Popups/EspionagePopup.lua` opens it from `Events.SpyMissionCompleted`, and also listens to `Events.LocalPlayerTurnEnd`. See [spies.md](../../findings/actions/spies.md#questions), question 1, and test it in a save with a mission about to end. Commit: `feat(core): close the spy mission popup for agent players`.

13. **Project built and rock band popups.** A popup shows each project the player completes, such as a space race launch, and each rock band concert in Gathering Storm. Each sets the `CINEMATIC` interface mode, holds the event queue, and waits for **Close**.

    Make the core mod close both for an agent player, as for the cinematic popups.

    `Base/Assets/UI/Popups/ProjectBuiltPopup.lua` locks with `ExclusivePopupManager:Lock` and fires `LuaEvents.ProjectBuiltPopup_Shown`.

    `DLC/Expansion2/UI/Additions/RockBandMoviePopup.lua` holds the event with `UI.ReferenceCurrentEvent()` and fires `LuaEvents.RockBandMoviePopup_Shown`. Confirmed in files.

    The rock band's `Close` also calls `Events.UnitStopCinematicAnimation`, and fires `LuaEvents.RockBandMoviePopup_OpenRockBandPopup`, which opens `RockBandPopup.lua` with the concert's result. Check that popup too, and pass the result to the agent. See [end-turn.md](../../findings/actions/end-turn.md#questions).

    Test it in a save with a project a turn from done, and a rock band next to a foreign city. Commit: `feat(core): close the project and rock band popups for agent players`.

## Done when

With an agent as the local player, a wonder that the player completes, a natural wonder the player finds, a tech, a civic, a boost, and a natural disaster show no popup and don't hold up the next request.

Neither does a Secret Society the player discovers or joins, a hero the player discovers, a great work the player creates, a historic moment, a new era and its review, a project, a rock band concert, or a World Congress session, its results, or an emergency it starts.

A war the agent declares leaves no leader screen open. A captured unit and a finished spy mission show no popup, and the agent gets their text.

## Record

- What each popup does to a request and the end turn call, and how the core mod closes it, in [findings/actions/end-turn.md](../../findings/actions/end-turn.md). The leader screen, in [findings/actions/war-and-peace.md](../../findings/actions/war-and-peace.md).
- How the core mod handles popups for an agent player, in [design/core/mod/README.md](../../design/core/mod/README.md).
