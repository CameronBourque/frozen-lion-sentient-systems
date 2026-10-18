# Build tooling

Status: open. Not built yet.

The bridge ships as one executable that Node SEA builds. [design/core/bridge.md](../design/core/bridge.md#decisions) says why. The release workflow runs `npm ci` at the repo root and `npm run build:exe` in the bridge workspace on a `windows-latest` runner, then checksums and uploads every file in `dist/`. `build:exe` must therefore leave only the executable in `dist/`.

## Questions

1. How large is the output?
2. Does the output run on a clean Windows machine with no Node installed?
3. Does Windows Defender or SmartScreen flag it?
4. Do the MCP SDK and the Vercel AI SDK bundle cleanly with esbuild?
5. Does `node --build-sea` on Windows need any extra step, such as removing the signature from the Node binary before it writes the program in?

## What we know now

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Build command | `node --build-sea <config>` builds the executable in one command on Node 26 | Unconfirmed on our setup | [Node.js 26.8.2 docs](https://nodejs.org/download/release/v26.8.2/docs/api/single-executable-applications.html) |
| Bundling | A SEA runs one script, so esbuild bundles `src/main.ts` and every dependency into one file first | Unconfirmed on our setup | Node.js 26.8.2 docs, same page |

## Method

1. Build a hello-world `main.ts` into an executable.
2. Add one real dependency, the MCP SDK, and build again.
3. Copy each executable to a folder outside the repo, such as `Downloads`, and run it there.
4. Record the size and any antivirus warnings.
5. Before the first release, run the released executable in Windows Sandbox, a clean Windows with no Node. Download it inside the Sandbox, so SmartScreen sees it as a new download. Phase 0 [step 12](../roadmap/phase-0/12-close-out.md) does this.

## Results

Nothing yet.

| Build | Size | Runs outside the repo | Runs in Windows Sandbox | Antivirus and SmartScreen | Notes |
| --- | --- | --- | --- | --- | --- |
| Hello-world | | | | | |
| With the MCP SDK | | | | | |

Date checked: not yet.
