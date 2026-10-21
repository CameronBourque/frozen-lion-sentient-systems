# Risks

What could go wrong, what it would cost, and the fallback. Open questions that a test can answer live in [findings/](findings/README.md), and the rows below link to them. See [rules/docs.md](rules/docs.md#risks).

| Risk | Impact | Fallback or mitigation | Tracked in |
| --- | --- | --- | --- |
| The FireTuner protocol is undocumented, slow, or unstable | The whole bridge depends on it | A hook DLL, found through reverse engineering, adds a native socket | [tuner-protocol.md](findings/tuner-protocol.md), [phase 0](roadmap/phase-0/README.md) |
| The tuner may not reach the core mod's Lua states | The bridge can't call the action API in the mod | Send generated Lua to the `InGame` and `GameCore_Tuner` states, as civ6-mcp does. The core mod keeps the turn signal and the UI | [lua-contexts.md](findings/lua-contexts.md), question 3 |
| A Lua state's index may change while the tuner stays connected | Commands run in the wrong state, or in none, with no clear error | The core mod reports each load, so the bridge lists the states again. Each command checks that it runs in the state it expects | [lua-contexts.md](findings/lua-contexts.md), questions 6 to 10 |
| The tuner may need the SDK on Windows | Nontechnical users need an extra install from the **Tools** section of the Steam library | First run checks for the SDK and walks the user through installing it | [tuner-setup.md](findings/tuner-setup.md), question 1 |
| The tuner may not work in online games | Advisors in online games depend on it | None yet | [multiplayer.md](findings/multiplayer.md) |
| Game state is large | Too much state makes turns slow and expensive | Measure, then trim. Facts go through `lookup` | [testing.md](design/testing.md#state-size), [phase 1](roadmap/phase-1/README.md) |
| Hotseat turns run one after another | Several agents can make you wait minutes between your turns | Handle trivial actions in plain code, run fewer deep reviews, and use smaller models where tests allow | [turn-loop.md](design/agents/turn-loop.md) |
| No sweat is hard to steer | Models default to reasonable play | Tune from logs, decision records, and playtests | [sweat-level.md](design/agents/sweat-level.md) |
| Some map-reveal mods change game data | A reveal could leak information to an agent | Pick a rendering-only reveal and test it | [cover-and-spectator.md](design/agents/cover-and-spectator.md#map-reveal), [phase 4](roadmap/phase-4/README.md) |
| The game property API may not be writable from the needed Lua state | Checkpoint IDs depend on it | None yet | [game-api.md](findings/game-api.md#game-properties-for-checkpoint-ids), question 7 |
| UI Lua may not be able to dismiss the hotseat pass screen | Agent turns must start without a click | None yet | [game-api.md](findings/game-api.md#questions), question 8 |
| macOS and Linux builds are untested | They decide which platforms ship | Ship Windows only until each platform passes the phase 0 gate on a real machine. macOS also needs signing and notarization, or Gatekeeper blocks the download | [distribution.md](design/distribution.md), [tuner-setup.md](findings/tuner-setup.md), question 2 |
| Antivirus tools can flag an unsigned executable | A nontechnical user may stop at the warning | Sign the code before the first release | [build-tooling.md](findings/build-tooling.md), question 2 |
| Some modded civs have thin Civilopedia text | Generated notes for those civs are weaker | Overrides, and better Civilopedia entries from mod authors | [knowledge-files.md](design/knowledge-files.md#civ-notes) |
| Cost per game | Users pay their own API bills | Measure in phase 1 and publish the results. Consider a spending limit in settings | [distribution.md](design/distribution.md#decisions), [phase 1](roadmap/phase-1/README.md) |
