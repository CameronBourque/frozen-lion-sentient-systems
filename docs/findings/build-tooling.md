# Build tooling

Status: open. No choice yet.

The bridge ships as one executable. The release workflow runs `npm ci` and `npm run build:exe` in `packages/core/bridge` on Node 22, then checksums and uploads every file in `dist/`. `build:exe` must therefore leave only the executable in `dist/`.

## Questions

1. Which tool builds the single executable: Node single executable applications (SEA), or `bun build --compile`?
2. How large is the output?
3. Does the output run on a clean Windows machine with no Node or Bun installed?
4. Does Windows Defender or SmartScreen flag it?
5. Do the MCP SDK and the Vercel AI SDK bundle cleanly with it?
6. Can CI build the Windows executable? The release job runs on `ubuntu-latest`.

## What we know now

| | Node SEA | Bun |
| --- | --- | --- |
| Runtime | Node, the same as dev and CI | Bun, a second runtime |
| Steps | Bundle to one file, for example with esbuild, generate a blob, and inject it with `postject` | One command |
| Building on Linux for Windows | Unconfirmed. It may need a Windows runner or a downloaded Windows Node binary | `--target bun-windows-x64`. Unconfirmed on our setup |

Everything in this table is unconfirmed until we test it.

## Method

1. Build a hello-world `main.ts` with each tool.
2. Add one real dependency, such as the MCP SDK, and build again.
3. Run each output on a machine or VM without Node or Bun.
4. Record the size and any antivirus warnings.

## Results

Nothing yet.

| Tool | Size | Runs on a clean machine | Antivirus | Builds on Linux CI | Notes |
| --- | --- | --- | --- | --- | --- |
| Node SEA | | | | | |
| Bun | | | | | |

Decision: none yet.

Date checked: not yet.
