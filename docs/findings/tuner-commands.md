# Tuner commands

Status: open. The bridge's probe confirmed how commands run, what the tag 3 reply carries, how large output arrives, reply order, and unprompted output. The rule that picks how the game runs a command is still open.

How the game runs a `CMD:` command and sends back its output. The wire format, message types, and byte dumps are in [tuner-protocol.md](tuner-protocol.md).

## Questions

1. How does the game choose between running a command inside `_cmdr = {<lua>}` and running it as a plain chunk? In the probe, each command that holds an `=` ran as a plain chunk. See [Probe results](#probe-results).

## What we know now

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| How commands run | `1+1` ran inside `_cmdr = {...}`, and its value came back in the tag 3 reply. `x = 5` set the global `x`, and `local a = 1` ran with no error, so both ran as plain chunks. A plain chunk's values don't come back | Confirmed | [Probe results](#probe-results) |
| Command values | On success the tag 3 payload is the command's values joined with `, `, such as `2, two, true`, or an empty string when there are none | Confirmed | [Probe results](#probe-results) |
| Complete output | All of a command's output arrives before its tag 3 reply. A 1,000,000-character print arrived intact as one output frame. 2,000 prints in one command arrived in order. No output arrived after any tag 3 reply | Confirmed | [Probe results](#probe-results) |
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

- **Hello check.** `npm run hello` on Windows on 2026-10-21 listed 124 states and ran three commands in `InGame` through the marker wrapper. A one-line print and a command over three lines, with a `local` and a trailing `--` comment, both came back as expected. `print("before the error")` and then `error("boom")` came back as a runtime error with the print before it. The message was `[string "(function()..."]:6: boom`, then a stack trace of five calls through `error`, `pcall`, and the wrapper.
- **Round-trip time.** From a send to its tag 3 reply took 18 to 54 ms, up to the 1,000,000-character print.
- **Late output.** No frame arrived in the 500 ms after any tag 3 reply.
- **Unprompted output.** One turn end on 2026-10-19 produced no frames on 4318 in the 48 seconds after the last command. One turn end during the probe's 60-second listen on 2026-10-21 produced no frames either. During the second run's listen, these actions each printed with no command running:

  | Action | Prints |
  | --- | --- |
  | Select a city, then deselect it | `PlotInfo: PlotInfo::OnCitySelectionChanged` with the city's details, once for each |
  | Move a unit that reveals two tiles of an ocean never seen before. The prints may come from the reveal or from the mouse passing over the ocean | Four `MapLabelManager: INDIAN OCEAN` prints with screen positions, at the same moment |
  | Open, then close the full-screen map | `InGame: Request to BulkHide( true, FullscreenMap ), Show on 0 = 1`, then the same with `false` and `0` |

Date checked: 2026-10-21.
