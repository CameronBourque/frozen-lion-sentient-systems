# Tuner setup

Status: open. civ6-mcp describes the setup. Not tested on Windows.

How a player turns on the FireTuner server, and what that costs them. [design/distribution.md](../design/distribution.md) depends on these answers, because the bridge does this setup for nontechnical users. The wire protocol is in [tuner-protocol.md](tuner-protocol.md).

## Questions

1. Does the Windows Options menu have the **Tuner** toggle, and does it write `EnableTuner 1` to `AppOptions.txt`?
2. Does the tuner open its port on Windows without the SDK installed?
3. Does turning on the tuner turn off achievements? If it does, does that last for one game or until the player turns the tuner off?
4. Which macOS and Linux builds open the tuner?

## What we know now

The setup notes come from the [civ6-mcp README](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/README.md) at commit `dd20190`, read on 2026-10-16.

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Switch in the file | `EnableTuner 1` under `[Debug]` in `AppOptions.txt`. The default is `0` | Confirmed | `AppOptions.txt`, line 75, on 2026-10-16 |
| Switch in the menu | On Windows, **Tuner (disables achievements)** in the gameplay options | Unconfirmed | civ6-mcp README, "1. Configure Civ 6" |
| Achievements | The menu label says the tuner turns off achievements | Unconfirmed | civ6-mcp README, "1. Configure Civ 6" |
| SDK requirement | On Windows, the tuner server is part of the SDK, not the base game. The SDK installs from the Steam library, under **Tools** | Unconfirmed | civ6-mcp README, "Windows: additional setup" |
| macOS | The menu doesn't show the toggle. Set `EnableTuner 1` in `AppOptions.txt` | Unconfirmed | civ6-mcp README, "1. Configure Civ 6" |
| Linux | The menu doesn't show the toggle. The tuner needs the native Linux build, because Proton and Wine builds don't open it | Unconfirmed | civ6-mcp README, "1. Configure Civ 6" and "Linux: additional notes" |

The SDK is installed on Cameron's machine, so question 2 needs another Windows machine or an SDK uninstall.

## Method

1. Close the game. Note the value of `EnableTuner` in `AppOptions.txt`, then set it to `0`.
2. Start the game, open **Options**, and look for **Tuner (disables achievements)** in the gameplay options. Turn it on, and close the game.
3. Check whether `AppOptions.txt` now has `EnableTuner 1`.
4. Start a game, and check whether port 4318 is listening, as step 2 of the [tuner protocol method](tuner-protocol.md#method) describes.
5. To answer question 3, look for any message about achievements while the tuner is on. Then turn the tuner off, restart the game, and check whether the message is gone.
6. To answer question 2, uninstall the SDK in Steam, or use a Windows machine without it, and repeat step 4.

## Results

Nothing yet.

| Question | Result | Date |
| --- | --- | --- |
| Menu toggle exists and writes the file | | |
| Port opens without the SDK | | |
| Achievements turn off, and for how long | | |
| macOS and Linux builds | | |

Date checked: sources on 2026-10-16. Running game: not yet.
