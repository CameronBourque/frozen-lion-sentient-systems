# Bridge

The external TypeScript program. It connects to the game over FireTuner, runs the agent loop through an MCP server, calls the model, and stores agent memory. It ships as a single executable.

Design: [docs/design/core/bridge.md](../../../docs/design/core/bridge.md). Protocol findings: [docs/findings/tuner-protocol.md](../../../docs/findings/tuner-protocol.md) and [docs/findings/tuner-commands.md](../../../docs/findings/tuner-commands.md).

## Layout

| Folder | Holds |
| --- | --- |
| `src/` | The code that ships in the executable |
| `test/` | Tests for `src/`, in the same folder structure. `test/tuner/fake-game.ts` is a stand-in for the game's tuner socket |
| `scripts/` | Dev tools for the bridge. They don't ship, and coverage doesn't count them |

## Scripts

Run each script from the repo root with `npm run <script> --workspace packages/core/bridge`, or from this folder with `npm run <script>`. The repo root has `lint`, `test`, and `coverage`, which cover every package.

| Script | What it does |
| --- | --- |
| `dev` | Runs `src/main.ts` with `tsx`. It connects to the game's tuner, retries until the game is running, logs the core mod's version and any active turn on each connect, and logs each line that the core mod prints. It runs until you press Ctrl+C |
| `typecheck` | Type-checks `src/`, `test/`, and `scripts/` with `tsc`. It emits no files |
| `build:exe` | Builds `dist/sentient-systems-bridge.exe` with esbuild and Node SEA. The release workflow runs it. See `scripts/build-exe.mjs` |
| `hello` | Checks the tuner client against the running game. It prints the state list, runs three commands in `InGame`, and exits with code 1 if a result is wrong. Run it after a change to `src/tuner/` |
| `probe` | Sends test commands to the running game's `InGame` state and prints every frame that comes back, to answer the [tuner command questions](../../../docs/findings/tuner-commands.md#questions). It needs a loaded game, and it retries until the game is running. The steps are in the [tuner command method](../../../docs/findings/tuner-commands.md#method) |
| `watch-states` | Lists the game's Lua states every 5 s while you play, and prints each change with the time. After a change, it sends a command to the old `InGame` index. It answers the [Lua state questions](../../../docs/findings/lua-contexts.md#questions). It runs until you press Ctrl+C |
