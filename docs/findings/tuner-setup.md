# Tuner setup

Status: open. The Windows menu toggle is confirmed in a running game. The SDK requirement and the macOS and Linux builds are untested.

How a player turns on the FireTuner server, and what that costs them. [design/distribution.md](../design/distribution.md) depends on these answers, because the bridge does this setup for nontechnical users. The wire protocol is in [tuner-protocol.md](tuner-protocol.md).

## Questions

1. Does the tuner open its port on Windows without the SDK installed?
2. Which macOS and Linux builds open the tuner?

## What we know now

The setup notes come from the [civ6-mcp README](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/README.md) at commit `dd20190`, read on 2026-10-16.

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Switch in the file | `EnableTuner 1` under `[Debug]` in `AppOptions.txt`. The default is `0` | Confirmed | `AppOptions.txt`, line 75, on 2026-10-16 |
| SDK requirement | On Windows, the tuner server is part of the SDK, not the base game. The SDK installs from the Steam library, under **Tools** | Unconfirmed | civ6-mcp README, "Windows: additional setup" |
| macOS | The menu doesn't show the toggle. Set `EnableTuner 1` in `AppOptions.txt` | Unconfirmed | civ6-mcp README, "1. Configure Civ 6" |
| Linux | The menu doesn't show the toggle. The tuner needs the native Linux build, because Proton and Wine builds don't open it | Unconfirmed | civ6-mcp README, "1. Configure Civ 6" and "Linux: additional notes" |

The SDK is installed on the Windows test machine, so question 1 needs another Windows machine or an SDK uninstall.

## Method

1. Close the game. Note the value of `EnableTuner` in `AppOptions.txt`, then set it to `0`.
2. Start the game, open **Options**, and look for **Tuner (disables achievements)**. Turn it on, and close the game.
3. Check whether `AppOptions.txt` now has `EnableTuner 1`.
4. Start a game, and check whether port 4318 is listening, as step 2 of the [tuner protocol method](tuner-protocol.md#method) describes.
5. To answer question 1, uninstall the SDK in Steam, or use a Windows machine without it, and repeat step 4.

## Results

| Question | Result | Date |
| --- | --- | --- |
| Menu toggle exists and writes the file | Yes. The Windows **Options** menu has **Tuner (disables achievements)**. Turning it on asks for a restart. `EnableTuner` was `0` before, and `AppOptions.txt` had `EnableTuner 1` after the game closed. Confirmed | 2026-10-19 |
| Port opens without the SDK | Not tested. With the SDK installed, the game opened port 4318, and FireTuner connected | 2026-10-19 |
| Achievements | The toggle's label says it turns off achievements. The game shows no other message while the tuner is on. Not tested further, because the test account has every achievement | 2026-10-19 |
| macOS and Linux builds | | |

Date checked: sources on 2026-10-16. Running game on Windows: 2026-10-19.
