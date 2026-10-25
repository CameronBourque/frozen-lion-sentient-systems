# Tuner commands

Status: open. The bridge's probe confirmed how commands run, what the tag 3 reply carries, how large output arrives, the output size limit, reply order, and unprompted output. The rule that picks how the game runs a command is still open.

How the game runs a `CMD:` command and sends back its output. The wire format, message types, and byte dumps are in [tuner-protocol.md](tuner-protocol.md).

## Questions

1. How does the game choose between running a command inside `_cmdr = {<lua>}` and running it as a plain chunk? In the probe, each command that holds an `=` ran as a plain chunk. See [Probe results](#probe-results).

## What we know now

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| How commands run | `1+1` ran inside `_cmdr = {...}`, and its value came back in the tag 3 reply. `x = 5` set the global `x`, and `local a = 1` ran with no error, so both ran as plain chunks. A plain chunk's values don't come back | Confirmed | [Probe results](#probe-results) |
| Command values | On success the tag 3 payload is the command's values joined with `, `, such as `2, two, true`, or an empty string when there are none | Confirmed | [Probe results](#probe-results) |
| Complete output | All of a command's output arrives before its tag 3 reply. A 1,000,000-character print arrived intact as one output frame. 2,000 prints in one command arrived in order. No output arrived after any tag 3 reply | Confirmed | [Probe results](#probe-results) |
| Output size limit | The limit is on a command's whole output, about 2 MiB, not on each print. From `SentientSystemsCore_UI`, one print of 2,097,022 characters arrived intact. With the state prefix, that line is 2,097,046 characters, 106 under 2 MiB. Two prints in one command, the first of 1,000,000 characters, arrived intact up to a second print of 1,096,980 characters, and failed at 1,096,990. Each print adds about 35 bytes of its own. A command over the limit sent no output frame and no tag 3 reply, and the connection answered no later command. The game logged no error. A new connection worked | Confirmed | [Behavior notes](#behavior-notes) |
| Reply order | The game runs commands one at a time, in the order they arrive. Commands sent without waiting got their output and tag 3 replies back in send order, a fast command after a slow one included | Confirmed | [Probe results](#probe-results) |
| Unprompted output | UI event handlers print with no command running, and their prints arrive on the tuner connection. Prints from three Lua states, `PlotInfo`, `MapLabelManager`, and `InGame`, arrived on the one connection, each with its state's prefix. An unprompted `InGame:` print looks the same as a command's output. A turn end printed nothing | Confirmed | [Behavior notes](#behavior-notes) |
| Runtime errors | A runtime error's message is the error, then `stack traceback:` and one line for each call, all in one string. The chunk name is the first line of the command, such as `[string "(function()..."]`. Inside the marker wrapper, line N of the caller's Lua is line N + 4 of the command | Confirmed | [Behavior notes](#behavior-notes) |

## Method

1. Turn on the tuner and start a game, as steps 1 and 2 of the [tuner protocol method](tuner-protocol.md#method) describe.
2. Close FireTuner, because the game takes one client at a time.
3. Run `npm run probe --workspace packages/core/bridge`.
4. When the probe prints `Listening for 60 s`, select a city, open and close the full-screen map, and end a turn.

## Results

### Probe results

The probe in `packages/core/bridge/scripts/probe.ts` ran each command in `InGame` on Windows on 2026-10-21. Each row shows the command, the frames that came back, and the time from the send to the tag 3 reply.

| Command | Output frames | Tag 3 payload | Time |
| --- | --- | --- | --- |
| `1+1` | None | `2` | 33 ms |
| `1+1, "two", true` | None | `2, two, true` | 22 ms |
| `x = 5` | None | Empty | 18 ms |
| `print(x, _cmdr and _cmdr.x)` | `InGame: 5\tnil` | Empty | 30 ms |
| `local a = 1` | None | Empty | 29 ms |
| `(function() local a = 2 print(a) return a end)()` | `InGame: 2` | Empty | 24 ms |
| The marker wrapper around `print("inside")` | `@@ss:begin:1`, `inside`, `@@ss:end:1:ok` | Empty | 20 ms |
| The marker wrapper around `error("boom")` | `@@ss:begin:2`, then `@@ss:end:2:` and an 822-character error that starts `[string "(function() print(` | Empty | 32 ms |
| The marker wrapper around `local end` | None | `ERR:Syntax Error: [string "(function() print(`, 202 characters | 29 ms |
| `print(string.rep("a", 1000000))` | One frame of 1,000,008 characters, `InGame: ` and then 1,000,000 `a` characters | Empty | 54 ms |
| A loop of 2,000 prints | 2,000 frames, `1` to `2000` in order | Empty | 50 ms |
| `print("first")`, `print("second")`, and `print("third")`, sent without waiting | Each command's print, then its tag 3 reply, in send order | Empty | 28 to 45 ms |
| A loop of 5,000,000 steps that prints `slow`, then `print("fast")`, sent without waiting | `slow`, its tag 3 reply, then `fast` and its tag 3 reply | Empty | 28 and 42 ms |

The marker wrapper is `(function() print("@@ss:begin:<id>") local ok, err = pcall(function() <lua> end) print("@@ss:end:<id>:" .. (ok and "ok" or tostring(err))) end)()`. Prints of 1,000, 10,000, and 100,000 characters arrived intact the same way, in 21 to 43 ms. A second run on 2026-10-21 got the same frames and values back, in 20 to 49 ms.

The chunk name in each error is the command text, not `_cmdr = {...}`, so the marker wrapper ran as a plain chunk. `x = 5` set the global `x`, and the previous command's `_cmdr` held no `x`, so `x = 5` ran as a plain chunk too.

### Behavior notes

- **Large prints from the core mod.** On 2026-10-23, the bridge sent `print(string.rep("a", <n>))` to `SentientSystemsCore_UI` in a single-player game, on a new connection for each size from 2,097,000 up. Each print up to the limit arrived as one line, in 29 to 73 ms from the send to the tag 3 reply:

  | Characters | Result | Time |
  | --- | --- | --- |
  | 1,000, 100,000, and 1,000,000, three times each | Arrived whole | 29 to 46 ms, after the first command on the connection, which took 379 ms |
  | 1,500,000 and 2,000,000 | Arrived whole | 41 and 73 ms |
  | 2,050,000, 2,090,000, 2,096,000, 2,097,000, 2,097,010, 2,097,020, and 2,097,022 | Arrived whole | 55 to 66 ms |
  | 2,097,023, 2,097,024, 2,097,026, 2,097,028, 2,097,030, 2,097,040, 2,097,050, 2,097,075, 2,097,090, 2,097,100, 2,097,200, 2,500,000, 3,000,000, and 4,000,000 | No reply in 10 to 60 s. A `print("pong")` sent next on the same connection got no reply either | None |

  On 2026-10-24, the bridge sent several prints in one command to `SentientSystemsCore_UI`, on a new connection for each command:

  | Prints in one command | Result | Time |
  | --- | --- | --- |
  | 2 of 1,000,000 characters | Arrived whole | 383 ms |
  | 1,000,000, then 1,096,900, 1,096,950, 1,096,960, 1,096,970, or 1,096,980 characters | Arrived whole | 150 to 369 ms |
  | 1,000,000, then 1,096,990 or 1,097,000 characters | No reply in 15 s | None |
  | 3 of 1,000,000 characters | No reply in 15 s | None |

  On 2026-10-24, the bridge read 2,500,001 bytes of JSON, a list of 500,000 `"é"` strings, through the core mod's stash, one piece per command. See **Stash** in [in-game-lua.md](../design/core/in-game-lua.md). `SentientSystems_Stash` encoded the list and printed `3` in 1,012 ms. Each `SentientSystems_PrintPiece` command took 29 to 36 ms, for pieces of 1,000,000, 1,000,000, and 500,001 bytes. The joined pieces parsed with `JSON.parse` into 500,000 `"é"` strings, with no U+FFFD replacement characters. A `SentientSystems_PrintPiece(1)` after the last piece raised `no stashed piece 1`.

- **Hello check.** `npm run hello` on Windows on 2026-10-21 listed 124 states and ran three commands in `InGame` through the marker wrapper. A one-line print and a command over three lines, with a `local` and a trailing `--` comment, both came back as expected. `print("before the error")` and then `error("boom")` came back as a runtime error with the print before it. The message was `[string "(function()..."]:6: boom`, then a stack trace of five calls through `error`, `pcall`, and the wrapper.
- **Round-trip time.** From a send to its tag 3 reply took 18 to 54 ms, up to the 1,000,000-character print.
- **Late output.** No frame arrived in the 500 ms after any tag 3 reply.
- **Turn signal.** On 2026-10-22, three turn ends in a single-player game each logged one `turn 0` in `npm run dev`. Each line appeared at the same moment the game showed the new turn, as far as the eye could tell.
- **Resync on connect.** On 2026-10-22 in single player, `npm run dev` started during the human's turn logged `core version 0.1.0` and `turn 0` within a second, and no turn ended. A restart in the same turn logged both again. Started during the AI turns, it logged only the version, and `turn 0` came from the turn event when the human's turn started. Started at the main menu, it warned that the core mod's state wasn't loaded, and after a game loaded it reconnected and logged the version.
- **Load line.** During a load, `CORE_LOADED` arrived on the connection 8 to 28 s before the socket reset at the loading screen's button.
- **Unprompted output.** One turn end on 2026-10-19 produced no frames on 4318 in the 48 seconds after the last command. One turn end during the probe's 60-second listen on 2026-10-21 produced no frames either. During the second run's listen, these actions each printed with no command running:

  | Action | Prints |
  | --- | --- |
  | Select a city, then deselect it | `PlotInfo: PlotInfo::OnCitySelectionChanged` with the city's details, once for each |
  | Move a unit that reveals two tiles of an ocean never seen before. The prints may come from the reveal or from the mouse passing over the ocean | Four `MapLabelManager: INDIAN OCEAN` prints with screen positions, at the same moment |
  | Open, then close the full-screen map | `InGame: Request to BulkHide( true, FullscreenMap ), Show on 0 = 1`, then the same with `false` and `0` |

Date checked: 2026-10-21, 2026-10-22 for the turn signal, resync, and load line, and 2026-10-23 and 2026-10-24 for the large prints from the core mod.
