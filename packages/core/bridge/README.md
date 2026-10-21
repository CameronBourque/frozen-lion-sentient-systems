# Bridge

The external TypeScript program. It connects to the game over FireTuner, runs the agent loop through an MCP server, calls the model, and stores agent memory. It ships as a single executable.

Design: [docs/design/core/bridge.md](../../../docs/design/core/bridge.md). Protocol findings: [docs/findings/tuner-protocol.md](../../../docs/findings/tuner-protocol.md).

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
| `dev` | Runs `src/main.ts` with `tsx` |
| `typecheck` | Type-checks `src/`, `test/`, and `scripts/` with `tsc`. It emits no files |
| `build:exe` | Builds `dist/sentient-systems-bridge.exe` with esbuild and Node SEA. The release workflow runs it. See `scripts/build-exe.mjs` |
| `probe` | Sends test commands to the running game's `InGame` state and prints every frame that comes back, to answer the [tuner protocol questions](../../../docs/findings/tuner-protocol.md#questions). It needs a loaded game, and it retries until the game is running. The steps are in the [tuner protocol method](../../../docs/findings/tuner-protocol.md#method) |
