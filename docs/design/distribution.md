# Distribution

How a nontechnical user gets and runs the project: three mods on the Steam Workshop, and a bridge executable on GitHub releases that launches the game and sets itself up. Version rules are in [versioning.md](versioning.md).

- The three mods ship on the Steam Workshop.
- The bridge ships as a single executable on GitHub releases. The Workshop description links to it. After the first install, the bridge [updates itself](core/bridge.md).
- The mod detects a missing bridge and shows an in-game message with setup steps.
- The bridge launches the game. The user runs a "Civ VI with agents" shortcut, and the bridge starts Civ VI through Steam and waits for the tuner connection. Civ VI Lua cannot start programs, so the mod cannot start the bridge.
- On first run, the bridge asks permission and then sets `EnableTuner` to `1` in `AppOptions.txt`.
- An in-game settings box takes the API key. The game sends the key to the bridge, and the bridge saves it.
- Windows is the first platform. Community workarounds connect to the tuner socket on macOS and Linux, so those platforms follow if the workarounds hold up.
- Gathering Storm is the first supported ruleset. Other rulesets follow.

## Open questions

- Should first run tell Windows users to turn on the **Tuner** option in the Options menu, instead of editing `AppOptions.txt`? It depends on [tuner-setup.md](../findings/tuner-setup.md) question 1.
- How does first run tell users that the tuner turns off achievements, before they agree to turn it on? How long achievements stay off is [tuner-setup.md](../findings/tuner-setup.md) question 3.

## Decisions

| Decision | Reason |
| --- | --- |
| Build for the Steam Workshop and nontechnical users | The goal includes sharing the mods with friends |
| Bridge on GitHub releases, linked from the Workshop | GitHub releases give versioning and bug reports, and users trust them more than an executable in a Workshop item |
| The bridge launches the game and sets `EnableTuner` | The mod cannot start programs, and users should not edit files |
| The user enters the API key in game, and the bridge stores it | Saves and multiplayer games share game setup parameters |
| Windows first, then macOS and Linux | Tuner workarounds exist for the other platforms |
| Gathering Storm first | One ruleset to support at the start |
| Publish measured costs in the mod description | Users pay their own API bills and should know the cost before they play |
