# FireTuner protocol

Status: confirmed. A Windows capture confirmed the port, the frame format, and each message type that FireTuner uses. One row from community sources is still unconfirmed on Windows.

The wire format between a client and the game. How the game runs commands and sends back their output is in [tuner-commands.md](tuner-commands.md).

## Questions

None are open. The unconfirmed rows below come from community sources, and nothing in the bridge depends on them yet.

## What we know now

Two open-source projects describe the protocol from their own use of it. [civ6-logger](https://github.com/PatrickJYKang/civ6-logger/blob/c21795250050447c89d42858afdf3decbac49bd8/docs/ARCHITECTURE.md), read at commit `c217952`, verified its notes on an Apple M4 Max. [civ6-mcp](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a), read at commit `dd20190`, is an MIT-licensed MCP server that lets LLM agents play full games. Sources read on 2026-10-16. The Windows capture on 2026-10-19 confirmed most of their framing and corrected some details. The dumps are in [Results](#results). How to turn the tuner on is in [tuner-setup.md](tuner-setup.md).

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Official client | `FireTuner2.exe` in the SDK | Confirmed | SDK folder |
| Port | `127.0.0.1:4318`. The game process, `CivilizationVI`, listens on it. It also listens on `127.0.0.1:4319` | Confirmed | `netstat` and `Get-NetTCPConnection` on Windows, 2026-10-19 |
| Port after a crash | After the game was ended from Task Manager and relaunched, it listened on 4318 and 4319 again under a new process ID. Steam did not need a restart. FireTuner kept retrying and reconnected by itself | Confirmed, one test | Windows, 2026-10-19 |
| Second port | Port 4319 has no Lua states. In single player, `APP:` gets the normal reply, `LSQ:` gets an empty list, and `CMD:0:print` gets an empty tag 3 reply with no output. In hotseat, `APP:` got the normal reply, and the next request, apparently `LSQ:`, crashed the game with `EXCEPTION_ACCESS_VIOLATION` reading `0x0`. Never send requests to 4319 | Confirmed | Windows, 2026-10-22. civ6-logger ARCHITECTURE.md, "Two ports, and which Lua state to use", describes the same empty port |
| Hotseat | The connection on 4318 drops when the game moves into the hotseat staging room. In the hotseat game, nothing listens on 4318, so no client can connect, even by hand. 4319 still listens. In single player, 4318 stays open | Confirmed | Windows, 2026-10-22 |
| Connections | The game accepts one client on 4318 at a time. While FireTuner was connected, 4318 was not in the listening state, and `Test-NetConnection 127.0.0.1 -Port 4318` failed. After FireTuner closed, the same test succeeded | Confirmed | Windows, 2026-10-19 |
| Framing | A 4-byte little-endian length, a 4-byte little-endian signed tag, then the payload. The length counts payload bytes only, including the trailing null byte. Both directions use this format | Confirmed | [Frame format](#frame-format) |
| Strings | The payload is UTF-8 strings, each ending in a null byte. A payload can hold several strings | Confirmed | [Message examples](#message-examples) |
| Tags | Each reply carries the tag of its request: `APP:` uses 4, `LSQ:` uses 0, and `CMD:` uses 3. Output frames use -1 (`0xFFFFFFFF`). civ6-logger sends `LSQ:` with tag 4 | Confirmed | [Message examples](#message-examples) |
| Handshake | FireTuner sends `APP:` with no name, then `LSQ:`. The game replies to `APP:` with three strings: `Civ6`, `Sid Meier's Civilization 6`, and the path of the game's `Base\Binaries\Debug` folder | Confirmed | [Message examples](#message-examples) |
| State list | Null-separated `<index>\0<name>\0` pairs, one per Lua state, in index order. `Main State` is 0. The names are in [lua-contexts.md](lua-contexts.md#lua-state-list) | Confirmed | [Message examples](#message-examples) |
| Run command | `CMD:<stateIndex>:<lua>` with tag 3 | Confirmed | [Message examples](#message-examples) |
| Output | Each `print` arrives as a tag -1 frame with the payload `O\0<text>\0`. Text printed in any state except `Main State` starts with the state name and a colon, such as `InGame: hello` | Confirmed | [Message examples](#message-examples) |
| End of a command | A tag 3 frame ends each command. On success its payload is one string, which holds the command's values. On a Lua error it is one string that starts with `ERR:` and holds the error and a stack trace, and no other tag 3 frame follows. What the values look like is in [tuner-commands.md](tuner-commands.md#what-we-know-now) | Confirmed | [Message examples](#message-examples) |
| Merged frames | The output frame and the tag 3 frame arrived in one TCP segment, so one read can hold more than one frame | Confirmed | [Message examples](#message-examples) |
| Recovery | After a bad handshake, the tuner often hangs until the game restarts | Unconfirmed | civ6-mcp README |

## Method

1. Close the game, then set `EnableTuner 1`. The game rewrites `AppOptions.txt` when it exits, so edit the file only while the game is closed.
2. Start a game. Load a save or start a new game, so the `InGame` state exists.
3. Install Wireshark with Npcap. Capture on **Adapter for loopback traffic capture** with the filter `tcp.port == 4318`.
4. Connect FireTuner and run commands in it.
5. Save the capture as `.pcapng`. Then use **Follow TCP Stream**, set **Show as** to **YAML**, and save it.

## Results

Captured with Wireshark on Windows, in a Duel game with Gathering Storm rules, on 2026-10-19.

### Frame format

```
offset  size  field
0       4     length: payload bytes, little-endian unsigned
4       4     tag: little-endian signed
8       n     payload: null-terminated UTF-8 strings
```

### Message examples

Each example shows the header bytes, then the payload as text. `\0` is a null byte.

**Connect, client to game.**

```
05000000 04000000 4150503a00
length 5, tag 4, "APP:\0"
```

**Connect reply, game to client.**

```
71000000 04000000 43697636 00 536964...
length 113, tag 4, "Civ6\0Sid Meier's Civilization 6\0E:\SteamLibrary\steamapps\common\Sid Meier's Civilization VI\Base\Binaries\Debug\0"
```

**State list, client to game.**

```
05000000 00000000 4c53513a00
length 5, tag 0, "LSQ:\0"
```

**State list reply, game to client.** The full reply is 2,350 bytes of payload for 124 states.

```
2e090000 00000000 30004d61696e20537461746500 3100...
length 2350, tag 0, "0\0Main State\01\0DebugHotloadCache\0 ... 123\0InvitePopup\0"
```

**`print("hello")` in `Main State`, client to game.**

```
15000000 03000000 434d443a303a7072696e74282268656c6c6f222900
length 21, tag 3, "CMD:0:print(\"hello\")\0"
```

**Reply, game to client.** Two frames arrived in one TCP segment.

```
08000000 ffffffff 4f0068656c6c6f00
length 8, tag -1, "O\0hello\0"
01000000 03000000 00
length 1, tag 3, "\0"
```

**`print("hello")` in `InGame`, client to game.**

```
17000000 03000000 434d443a3131393a7072696e74282268656c6c6f222900
length 23, tag 3, "CMD:119:print(\"hello\")\0"
```

**Reply, game to client.**

```
10000000 ffffffff 4f00496e47616d653a2068656c6c6f00
length 16, tag -1, "O\0InGame: hello\0"
01000000 03000000 00
length 1, tag 3, "\0"
```

**`error("boom")` in `InGame`, client to game.**

```
16000000 03000000 434d443a3131393a6572726f722822626f6f6d222900
length 22, tag 3, "CMD:119:error(\"boom\")\0"
```

**Error reply, game to client.** No other frame followed.

```
bd000000 03000000 4552523a52756e74696d65...
length 189, tag 3, "ERR:Runtime Error: [string \"_cmdr = {error(\"boom\")}\"]:1: boom\nstack traceback:\n\t[C]: in function 'error'\n\t[string \"_cmdr = {error(\"boom\")}\"]:1: in function '(main chunk)'\r\nLua callstack:\r\n\0"
```

### Behavior notes

- **Round-trip time.** From a request to its reply took 19 to 27 ms for the handshake and for each command.
- **Segments.** Each reply arrived in one TCP segment, the 2,358-byte state list included.

Date checked: 2026-10-19.
