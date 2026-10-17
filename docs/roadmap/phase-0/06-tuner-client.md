# Step 6: Tuner client

Build the bridge's tuner client as small modules under `src/tuner/`, from the frame format captured in [step 3](03-capture-protocol.md). Part of [phase 0](README.md).

## Tasks

1. **`framing.ts`.** Write a pure `encodeFrame(...)` function and a streaming `FrameDecoder` that handles split and merged TCP chunks. Test it with the hex dumps from step 3. Framing is the easiest part to unit-test. Put its tests in `framing.test.ts`, which `npm test` runs.
2. **`connection.ts`.** Open a TCP connection to `127.0.0.1:<port>`, and add:
   - reconnect with backoff when the game isn't running or closes,
   - the events `connected`, `disconnected`, and `frame`.
3. **`client.ts`.** Build the protocol layer on top of the connection, with:
   - `listStates(): Promise<LuaState[]>`, with index and name,
   - `findState(name)`, which looks a state up by name each time you connect, because indexes may change between loads,
   - `run(stateName, lua)`, which sends the command,
   - an `output` event stream that splits output into lines.
4. **`src/scripts/hello.ts`.** Write a script that connects, lists states, runs `print("hello from bridge")` in one state, and prints what comes back.

## Done when

`tsx src/scripts/hello.ts` against a running game prints the state list and the echoed line.

## Record

The answer to question 10 and the behavior notes, in [tuner-protocol.md](../../findings/tuner-protocol.md#behavior-notes).
