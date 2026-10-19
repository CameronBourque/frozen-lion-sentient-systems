# Distribution

How a nontechnical user gets and runs the project: three mods on the Steam Workshop, and a bridge executable on GitHub releases that launches the game and sets itself up. Version rules are in [versioning.md](versioning.md).

- The three mods ship on the Steam Workshop.
- The bridge ships as a single executable on GitHub releases. The Workshop description links to it. After the first install, the bridge [updates itself](core/bridge.md).
- The mod detects a missing bridge and shows an in-game message with setup steps.
- The bridge launches the game. The user runs a "Civ VI with agents" shortcut, and the bridge starts Civ VI through Steam and waits for the tuner connection. Civ VI Lua cannot start programs, so the mod cannot start the bridge.
- On first run, the bridge asks permission and then sets `EnableTuner` to `1` in `AppOptions.txt`. The permission prompt and the Workshop description say that achievements are off while the tuner is on.
- An in-game settings box takes the API key. The game sends the key to the bridge, and the bridge saves it.
- Windows is the first platform. The tuner also works on macOS and on the native Linux build of Civ VI, where players turn it on in `AppOptions.txt`. It doesn't work under Proton or Wine. See [tuner-setup.md](../findings/tuner-setup.md). Each platform ships once someone has run the phase 0 gate on it, and releases from before then have no build for it. macOS builds also need signing and notarization, or Gatekeeper blocks them.
- Gathering Storm is the first supported ruleset. Other rulesets follow.

## Open questions

- Should first run tell Windows users to turn on the **Tuner** option in the Options menu, instead of editing `AppOptions.txt`? The toggle exists on Windows and writes the file. See [tuner-setup.md](../findings/tuner-setup.md#results).

## Decisions

| Decision | Reason |
| --- | --- |
| Build for the Steam Workshop and nontechnical users | The goal includes sharing the mods with friends |
| Bridge on GitHub releases, linked from the Workshop | GitHub releases give versioning and bug reports, and users trust them more than an executable in a Workshop item |
| The bridge launches the game and sets `EnableTuner` | The mod cannot start programs, and users should not edit files |
| Tell users that achievements are off while the tuner is on | The toggle's label says so. Testing how long they stay off needs an account with achievements left to earn, and the warning is the same either way. See [tuner-setup.md](../findings/tuner-setup.md#results) |
| The user enters the API key in game, and the bridge stores it | Saves and multiplayer games share game setup parameters |
| Windows first, then Linux and macOS, each once it is tested | The tuner works on all three, but each platform needs a machine to run the gate on. A Linux test machine exists. macOS also needs signing and notarization |
| Gathering Storm first | One ruleset to support at the start |
| Publish measured costs in the mod description | Users pay their own API bills and should know the cost before they play |
