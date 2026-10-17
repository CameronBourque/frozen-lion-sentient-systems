# FireTuner protocol

Status: open. Two community projects describe the protocol. Nothing captured on Windows yet.

## Questions

1. Which port does the game listen on, and does it change?
2. What does a frame look like: length prefix size, byte order, and any type or tag field?
3. Are strings null-terminated, length-only, or both?
4. What does the client send when it connects (the handshake)?
5. Which command lists the Lua states, and what does the reply look like?
6. Which command runs Lua in one state, and how does it name the state?
7. How do `print` output and Lua errors come back? Does each line carry its state?
8. Does the game send output that no command asked for, such as prints from event handlers?
9. Can more than one client connect at once, for example FireTuner and the bridge?
10. What are the round-trip time for a small command and the largest output that arrives intact?

## What we know now

Two open-source projects describe the protocol from their own use of it. [civ6-logger](https://github.com/PatrickJYKang/civ6-logger/blob/c21795250050447c89d42858afdf3decbac49bd8/docs/ARCHITECTURE.md) by PatrickJYKang, read at commit `c217952`, verified its notes on an Apple M4 Max. [civ6-mcp](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a) by lmwilki, read at commit `dd20190`, is an MIT-licensed MCP server that lets LLM agents play full games. Treat their details as unconfirmed until the Windows capture in the [method](#method) matches them. Sources read on 2026-10-16. How to turn the tuner on is in [tuner-setup.md](tuner-setup.md).

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Official client | `FireTuner2.exe` in the SDK | Confirmed | SDK folder |
| Port | `127.0.0.1:4318`. A second port, `4319`, completes the handshake but lists no Lua states. After a crash, `4318` may not come back until you restart the game and Steam | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "Two ports, and which Lua state to use" |
| Framing | A 4-byte little-endian unsigned length, a 4-byte little-endian signed tag, then the payload. In outgoing frames, the length is the payload byte count. The payload is UTF-8 text with a trailing null byte | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "The FireTuner wire protocol". The byte widths are in civ6-mcp's [`tuner_client.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/tuner_client.py#L18) |
| Handshake | Send `APP:<name>` with tag 4, then `LSQ:` with tag 4. The game replies with an app ID frame, then a state list frame | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "The FireTuner wire protocol" |
| State list | Null-separated `<index>\0<name>\0` pairs, one per Lua state, about 98 in all. The state names are in [lua-contexts.md](lua-contexts.md#state-names-from-other-projects) | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "The FireTuner wire protocol" |
| Run command | `CMD:<stateIndex>:<lua>` with tag 3 | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "The FireTuner wire protocol" |
| Output | Frames with tag `0xFFFFFFFF` and the payload `<channel>\0<text>\0`. A tag 3 ack ends the command | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "The FireTuner wire protocol" |
| Complete output | civ6-logger appends a unique `print` to each command and reads frames until that text arrives, because TCP can split the output | Unconfirmed on Windows | civ6-logger ARCHITECTURE.md, "The FireTuner wire protocol" |
| Connections | The game allows one tuner connection at a time. Close FireTuner before another client connects | Unconfirmed | civ6-mcp README |
| Recovery | After a bad handshake, the tuner often hangs until the game restarts | Unconfirmed | civ6-mcp README |

## Method

1. Close the game, then set `EnableTuner 1`. The game rewrites `AppOptions.txt` when it exits, so edit the file only while the game is closed.
2. Start a game and run `netstat -ano | findstr LISTENING`. Match the PID to the game process in Task Manager to find the port.
3. Install Wireshark with Npcap, and select loopback capture support. Capture on the loopback adapter with the filter `tcp.port == <port>`.
4. In FireTuner, do one action at a time and note the time of each:
   - connect,
   - load the Lua state list,
   - run `print("hello")` in one state,
   - run `print("hello")` in a different state,
   - run `error("boom")`,
   - end a turn in the game and watch for unprompted output.
5. For each action, use **Follow TCP Stream** and save the hex dump.

## Results

Nothing yet. Fill in the sections below.

### Frame format

```
offset  size  field
0       ?     length
?       ?     type or tag
?       ?     payload
```

### Message examples

For each message type, add the action, the direction (client to game, or game to client), the hex dump, and the decoded text.

### Behavior notes

Latency, output limits, merged prints, and behavior with more than one client.

Date checked: not yet.
