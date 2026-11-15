# Popups for agent players

Make the core mod close or skip the popups and screens that wait for a click, so an agent player is never held up by a screen it can't see. Part of [phase 1](README.md).

Each task first records whether its popup stops a request and the end turn call, with `endTurn` from `src/actions/turn.ts`. With `force`, it ends the turn while a blocker is left. See [design/core/mod/actions/turn.md](../../design/core/mod/actions/turn.md).

## Tasks

1. **Cinematic popups.** Make the core mod skip the cinematic popups for an agent player, so no one has to press **Close**.

   Start with `WonderBuiltPopup.lua`, then check the other popups that set the mode. See [ending the turn](../../findings/actions/end-turn.md#questions). Commit: `feat(core): skip the cinematic popups for agent players`.

2. **Natural disaster popups.** Make the core mod skip the popup for a flood, a drought, a storm, an eruption, or another weather event for an agent player, as for the cinematic popups.

   `DLC/Expansion2/UI/Additions/NaturalDisasterPopup.lua` sets the `CINEMATIC` interface mode when it opens and `SELECTION` when it closes, as the wonder popup does.

   Commit: `feat(core): skip the natural disaster popups for agent players`.

3. **Tech, civic, and boost popups.** A popup shows each tech and civic the player completes, and each boost, and waits for **Close** or **Continue**. Neither holds anything, but each keeps the player from the pause menu.

   Make the core mod turn them off for an agent player with `LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups()`, as the tutorial does, when each load ends. See [popups.md](../../findings/actions/plain-popups.md#tech-civic-and-boost-popups).

   Commit: `feat(core): turn off the tech and civic popups for agent players`.

4. **Secret Society and hero popups.** A popup shows each Secret Society the player discovers or joins, and each hero the player discovers in the Heroes and Legends mode, and waits for **Continue**.

   Neither holds anything, so the turn goes on, but each keeps the player from the pause menu. Make the core mod close both for an agent player.

   `DLC/Ethiopia/UI/Additions/SecretSocietyPopup.lua` and `DLC/Babylon/UI/Additions/HeroesPopup.lua` open by themselves from their notifications, with a plain `UIManager:QueuePopup`.

   Each `Close` is only `UIManager:DequeuePopup`, and neither fires an event of its own. They open from notifications at any time, so the core mod dequeues each one in the popup queue when a batch of game events or a load ends. See [popups.md](../../findings/actions/plain-popups.md#secret-society-and-hero-popups).

   Commit: `feat(core): close the secret society and hero popups for agent players`.

5. **Natural wonder popup.** When the player first sees a natural wonder, a popup shows it and waits for **Close**. It holds the engine's event queue as the wonder built popup does, and held the start of a turn. Then make the core mod close it for an agent player, as for the cinematic popups.

   `Base/Assets/UI/Popups/NaturalWonderPopup.lua` fires `LuaEvents.NaturalWonderPopup_Shown` right after its lock. See [popups.md](../../findings/actions/popups.md#natural-wonder-popup), which has the steps of its `Close` and a live close.

   Commit: `feat(core): close the natural wonder popup for agent players`.

6. **Historic moment popups.** In Rise and Fall, a popup shows some of the historic moments that earn the player era score. It doesn't keep the player from the pause menu, but it waits for **Close**.

   Make the core mod close it for an agent player.

   `DLC/Expansion2/UI/Additions/HistoricMoments.lua` queues itself with `UIManager:QueuePopup`, so the core mod closes it with the hero and Secret Society popups, and also on `Events.UIIdle`. It sends `LuaEvents.HistoricMoments_Closed` after, for the launch bar. See [plain-popups.md](../../findings/actions/plain-popups.md#historic-moment-popup).

   Commit: `feat(core): close the historic moment popups for agent players`.

7. **Era popups.** When a new era starts, a popup shows it, then the era review popup shows the age the player earned, golden, normal, or dark, before the dedication choice. Make the core mod close both for an agent player.

   `DLC/Expansion2/UI/Additions/EraCompletePopup.lua` locks, then closes itself when its animation ends, so it needs nothing. `EraReviewPopup.lua` queues itself with `UIManager:QueuePopup`, so the core mod closes it with the other plain popups.

   Its **Continue** opens the dedication popup, which the dedication action doesn't need. See [plain-popups.md](../../findings/actions/plain-popups.md#era-popups).

   Commit: `feat(core): close the era popups for agent players`.

8. **Great work popup.** A popup shows each great work the player creates, such as an artifact, a painting, or a relic, and waits for **Close**. It holds nothing.

   `Base/Assets/UI/GreatWorkShowcase.lua` shows by unhiding its context, not through the popup queue, so the core mod hides it with the other plain popups and plays its stop sounds. See [plain-popups.md](../../findings/actions/plain-popups.md#great-work-popup).

   Commit: `feat(core): close the great work popup for agent players`.

9. **World Congress popups.** When a session starts, the congress intro opens with **Continue**, which opens the voting screen. After a session, the results screen opens.

   The core mod dequeues the intro, so the voting screen and the between-turns screen after it never open, and the vote action votes without them. It closes the voting and results screen through `LuaEvents.DiplomacyActionView_HideCongress`, which runs its own close.

   See [congress-popups.md](../../findings/actions/congress-popups.md). Commit: `feat(core): close the World Congress popups for agent players`.

10. **Leader screen.** A peace that `proposePeace` makes leaves the leader screen open on the overview. A war that `declareWar` declares doesn't, since the core mod closes the AI's goodbye.

    With no session open, the leader screen shows only the overview, so the core mod closes it with the other plain popups. It presses the screen's own **X** with `DoLeftClick` on `/InGame/DiplomacyActionView/CloseButton`. See [the leader screen](../../findings/actions/war-and-peace.md#the-leader-screen).

    Commit: `feat(core): close the leader screen for agent players`.

11. **Unit captured popup.** When a unit of the player's is captured, or the player captures one, a dialog names the other civ and waits for **OK**. It holds nothing.

    `Base/Assets/UI/Popups/UnitCaptured.lua` raises it through the shared `InGamePopup` dialog with `LuaEvents.OnRaisePopupInGame("UnitCaptured", options)`. After that raise, the core mod presses the dialog's own button, which it finds through `GetChildren()`. See [in-game-dialogs.md](../../findings/actions/in-game-dialogs.md).

    Commit: `feat(core): close the unit captured popup for agent players`.

12. **Spy mission popup.** When a spy's mission ends, a popup shows the result and waits for **OK**. It holds nothing, so the core mod dequeues it as a plain popup. The result reaches the agent through task 15.

    `Base/Assets/UI/Popups/EspionagePopup.lua` opens it from `Events.SpyMissionCompleted`. A counterspy mission's **Renew** isn't needed, since the agent starts the mission again when the spy is idle. See [spies.md](../../findings/actions/spies.md#mission-popup). Commit: `feat(core): close the spy mission popup for agent players`.

13. **Project built and rock band popups.** A popup shows each project the player completes, such as a space race launch, and each rock band concert in Gathering Storm. Each sets the `CINEMATIC` interface mode, holds the event queue, and waits for **Close**.

    Each `Close` does more, such as showing the next project, or stopping the concert's camera and opening `RockBandPopup.lua` with the result.

    So the core mod presses each one's `Close` button with the plain popups, and dequeues `RockBandPopup`. The result reaches the agent through task 15. See [popups.md](../../findings/actions/popups.md#project-built-popup).

    Commit: `feat(core): close the project and rock band popups for agent players`.

14. **Emergency popup.** When an emergency is declared, a popup shows it and waits for **OK**. With Gathering Storm, every emergency begins through the congress vote, so the popup asks nothing.

    `DLC/Expansion2/UI/Additions/WorldCrisisPopup.lua` queues itself with `UIManager:QueuePopup`, so the core mod closes it with the other plain popups. Its **OK** also sends `ACCEPT_EMERGENCY`, which changed nothing the player can see, so the core mod leaves it out. See [congress-popups.md](../../findings/actions/congress-popups.md#emergency-popup).

    Commit: `feat(core): close the emergency popup for agent players`.

15. **Event messages.** The core mod closes the unit captured dialog and the spy mission and rock band result popups, so the agent never reads their text. Add a short list of recent events to the state, kept for the agent's next turn as the leader messages are, with each one's turn and text.

    Fill it from the options of the `UnitCaptured` raise, the history of each mission `Events.SpyMissionCompleted` names, and the result of each concert `Events.PostTourismBomb` names. See [in-game-dialogs.md](../../findings/actions/in-game-dialogs.md#questions), question 1, and [spies.md](../../findings/actions/spies.md#mission-popup).

    Test it with a captured builder, a finished spy mission, and a concert. Commit: `feat(core): add the event messages to the state`.

16. **Rock band concert action.** No action starts a concert, so the agent can't use a rock band. `UnitOperationTypes.TOURISM_BOMB` is nil, so send the hash of `UNITOPERATION_TOURISM_BOMB` from `GameInfo.UnitOperations`, which started one from the tuner.

    Add one, with the game's reasons when it can't start.

    Test it with a rock band on a foreign district. Commit: `feat(core): add the rock band concert action`.

17. **Close the lock popups with their own buttons.** `SENTIENTSYSTEMS_POPUPS` repeats the `Close` of the wonder built, natural wonder, and natural disaster popups. It never resets a popup's own lock, so a later one may only queue.

    Move them to the plain popups with `closeButton`, as task 13 does. Keep the camera stop on `GameCoreEventPlaybackComplete`, and the meteor and comet second lock release only if their `Close` doesn't release it.

    Test a wonder, a natural wonder and its camera, a disaster, and a meteor shower or comet. Commit: `refactor(core): close the lock popups with their own buttons`.

## Done when

With an agent as the local player, a wonder that the player completes, a natural wonder the player finds, a tech, a civic, a boost, and a natural disaster show no popup and don't hold up the next request.

Neither does a Secret Society the player discovers or joins, a hero the player discovers, a great work the player creates, a historic moment, a new era and its review, a project, a rock band concert, or a World Congress session, its results, or an emergency it starts.

A war the agent declares leaves no leader screen open. A captured unit, a finished spy mission, and a concert show no popup, and the agent gets their text in the state. The agent can start a concert.

## Record

- What each popup does to a request and the end turn call, and how the core mod closes it, in [findings/actions/popups.md](../../findings/actions/popups.md) and the files beside it. The leader screen, in [findings/actions/war-and-peace.md](../../findings/actions/war-and-peace.md).
- How the core mod handles popups for an agent player, in [design/core/mod/README.md](../../design/core/mod/README.md).
