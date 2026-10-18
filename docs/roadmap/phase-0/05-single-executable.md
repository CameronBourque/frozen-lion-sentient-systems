# Step 5: Build the single executable

Build the bridge into one Windows executable with Node SEA, and wire it into the release workflow. Part of [phase 0](README.md). The choices behind this step are in [design/core/bridge.md](../../design/core/bridge.md#decisions).

## Tasks

1. From the repo root, install `esbuild` as a root dev dependency.
2. Add a bridge script `"build:exe"` that does two things:
   - esbuild bundles `src/main.ts` and its dependencies into one file in `build/`,
   - `node --build-sea` turns that file into `dist/sentient-systems-bridge.exe`.

   The release workflow uploads every file in `dist/`, so leave only the executable there.
3. Follow the [build tooling method](../../findings/build-tooling.md#method). Build a hello-world first, then add the MCP SDK and build again. Copy each `.exe` to a folder outside the repo, such as `Downloads`, and run it there.
4. In `.github/workflows/release.yml`, change the `bridge` job:
   - Run it as a matrix with one entry, `os: windows-latest`, so a later platform is one more entry.
   - Run `npm ci` at the repo root, then `npm run build:exe --workspace packages/core/bridge`.
   - Give the upload step `shell: bash`, so `sha256sum` and `gh` work on the Windows runner.

## Done when

`npm run build:exe --workspace packages/core/bridge` leaves one runnable `.exe` in `dist/`, and it runs from a folder outside the repo. `actionlint` passes on the changed release workflow.

## Record

The size, the antivirus result, and how the MCP SDK bundled, in [build-tooling.md](../../findings/build-tooling.md#results).
