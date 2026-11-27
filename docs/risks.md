# Risks

What could go wrong, what it would cost, and the fallback. Open questions that a test can answer live in [findings/](findings/README.md), and the rows below link to them. See [rules/docs.md](rules/docs.md#risks).

- **The FireTuner protocol is undocumented, slow, or unstable.** Impact: The whole bridge depends on it. Fallback or mitigation: Proven in single player in [phase 0](roadmap/phase-0/README.md).

  The bridge lists cities, moves a unit, and gets the turn signal within about a second, and the released executable passes the same checks.

  In [phase 1](roadmap/phase-1/README.md), Claude Code played 10 turns through it with no `ERROR` lines. Once, the game stopped listening on 4318 after a long session, so that question stays open.

  If the tuner fails later, a hook DLL, found through reverse engineering, adds a native socket. Tracked in: [tuner/protocol.md](findings/tuner/protocol.md#results), [game-api.md](findings/game-api.md#results), [build-tooling.md](findings/build-tooling.md#results).
- **The bridge's state list goes stale while the tuner stays connected.** Impact: After a quit to the main menu, the socket stays open and `InGame` is gone. A later load may move states to new indexes.

  Commands then fail or run in the wrong state. Fallback or mitigation: The core mod's `GAME_READY` line drops the bridge's state list after each load, so the next command lists the states again.

  Each command checks its state with `ContextPtr:GetID()`. On `ERR:Invalid Lua State`, the bridge lists the states again. Tracked in: [lua/state-list.md](findings/lua/state-list.md#state-list-over-a-session), question 1.
- **The tuner closes in hotseat.** Impact: Agents can't act in a hotseat game, so you can't play alongside agents. Fallback or mitigation: Phase 0 and the MVP stay single player.

  A later test puts an agent in a computer slot with the native AI held back. See [slot-type.md](design/agents/slot-type.md#computer-slot-test). Backups: live reload of a UI Lua file for input with `Lua.log` for output, then a hook DLL. Tracked in: [tuner/multiplayer.md](findings/tuner/multiplayer.md#hotseat).
- **The tuner closes in online games.** Impact: Advisors can't read your state through the tuner in an online game. Fallback or mitigation: Advisors start in single player.

  The core mod still runs online and its prints reach `Lua.log`, so a read-only channel through the log may work. See [advisors.md](design/advisors.md#open-questions). Backup: a hook DLL. Tracked in: [tuner/multiplayer.md](findings/tuner/multiplayer.md#online).
- **Game state is large.** Impact: Too much state makes turns slow and expensive. Fallback or mitigation: Measure, then trim. Facts go through `read_civilopedia`. Tracked in: [testing.md](design/testing.md#state-size), [phase 2](roadmap/phase-2/README.md).
- **Agent turns may run one after another.** Impact: Several agents can make you wait minutes between your turns. Fallback or mitigation: Handle trivial actions in plain code, run fewer deep reviews, and use smaller models where tests allow. Tracked in: [turn-loop/](design/agents/turn-loop/README.md).
- **No sweat is hard to steer.** Impact: Models default to reasonable play. Fallback or mitigation: Tune from logs, decision records, and playtests. Tracked in: [sweat-level.md](design/agents/sweat-level.md).
- **Some map-reveal mods change game data.** Impact: A reveal could leak information to an agent. Fallback or mitigation: Pick a rendering-only reveal and test it. Tracked in: [cover-and-spectator.md](design/agents/cover-and-spectator.md#map-reveal), [phase 6](roadmap/phase-6/README.md).
- **The game property API may not be writable from the needed Lua state.** Impact: Checkpoint IDs depend on it. Fallback or mitigation: None yet. Tracked in: [game-api.md](findings/game-api.md#game-properties-for-checkpoint-ids), question 1.
- **UI Lua may not be able to dismiss the hotseat pass screen.** Impact: If games with you and agents use hotseat, agent turns must start without a click. Fallback or mitigation: None yet. Tracked in: [game-api.md](findings/game-api.md#questions), question 2.
- **macOS and Linux builds are untested.** Impact: They decide which platforms ship.

  Fallback or mitigation: Ship Windows only until each platform passes the phase 0 gate on a real machine. macOS also needs signing and notarization, or Gatekeeper blocks the download. Tracked in: [distribution.md](design/distribution.md), [tuner/setup.md](findings/tuner/setup.md), question 1.
- **Antivirus tools flag the unsigned executable.** Impact: SmartScreen blocks the download on its first run, and a nontechnical user may stop at the warning. Fallback or mitigation: Sign the code before the first release. Tracked in: [build-tooling.md](findings/build-tooling.md#what-we-know-now).
- **The Civilopedia's text is written for human players.** Impact: It leans on context a player brings, such as the screens, the icons, and play experience, so an agent may misread a rule or miss a number that only the screen shows.

  Fallback or mitigation: The lookup gives the row's stats beside the text. Concept guides fill the gaps that the phase 2 games show. Tracked in: [knowledge-files.md](design/knowledge-files.md#layers), [findings/civilopedia.md](findings/civilopedia.md#titles-and-text).
- **Some modded civs have thin Civilopedia text.** Impact: Generated notes for those civs are weaker. Fallback or mitigation: Overrides, and better Civilopedia entries from mod authors. Tracked in: [knowledge-files.md](design/knowledge-files.md#civ-notes).
- **Plan sign-in depends on each provider's terms.** Impact: A provider can change or end plan access for apps like the bridge, and Anthropic hasn't approved Claude plan login.

  xAI publishes no way for an app it hasn't announced to use its plan sign-in. Fallback or mitigation: API keys work for every provider.

  The Claude agent SDK mode stays behind a flag until Anthropic approves. xAI's plan sign-in gets a step only once xAI answers. Tracked in: [plan-access/anthropic.md](findings/plan-access/anthropic.md), [plan-access/xai.md](findings/plan-access/xai.md), [run-modes.md](design/core/run-modes.md#claude-runner).
- **Cost per game.** Impact: Users pay their own API bills. Fallback or mitigation: Measure in phase 2 and publish the results. Spending limits per turn and per run stop the agent, as [turn-loop/stopping.md](design/agents/turn-loop/stopping.md) describes. Tracked in: [distribution.md](design/distribution.md#decisions), [phase 2](roadmap/phase-2/README.md).
