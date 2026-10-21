# Build tooling

Status: open. The executable builds and runs on the development machine, and SmartScreen blocks the released download. It still needs a test on a clean Windows with no Node.

The bridge ships as one executable that Node SEA builds. [design/core/bridge.md](../design/core/bridge.md#decisions) says why. The release workflow runs `npm ci` at the repo root and `npm run build:exe` in the bridge workspace on a `windows-latest` runner, then checksums and uploads every file in `dist/`. `build:exe` must therefore leave only the executable in `dist/`.

## Questions

1. Does the output run on a clean Windows machine with no Node installed?

## What we know now

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Build command | `node --build-sea sea-config.json` builds the executable in one command on Node 26. `packages/core/bridge/scripts/build-exe.mjs` runs it after esbuild | Confirmed on Node 26.12.0 | Local build, 2026-10-20 |
| Bundling | A SEA runs one script, so esbuild bundles `src/main.ts` and every dependency into one CommonJS file, `build/main.cjs`, first | Confirmed with esbuild 0.28.2 | Local build, 2026-10-20 |
| Output folder | `--build-sea` does not create the output folder. It fails with "no such file or directory", so the build script creates `dist/` first | Confirmed | Local build, 2026-10-20 |
| Signature | The output is unsigned. `--build-sea` needs no extra step for the signature of the Node binary, and it prints no warning about it | Confirmed | `Get-AuthenticodeSignature` reports `NotSigned`, 2026-10-20 |
| Size | About 105 MB. Almost all of it is the Node runtime. The MCP SDK and the AI SDK add about 2 MB | Confirmed | [Results](#results) |
| SmartScreen | Blocks the released executable the first time it runs after a download. The dialog says "Windows protected your PC" and shows only **Don't run**, beside a **More info** link. **More info** adds a **Run anyway** button, which starts it. The executable is unsigned and has no download history | Confirmed, one machine | `core-v0.1.0` download on Windows 10, 2026-10-21 |

## Method

1. Build a hello-world `main.ts` into an executable.
2. Add one real dependency, the MCP SDK, and build again.
3. Copy each executable to a folder outside the repo, such as `Downloads`, and run it there.
4. Record the size and any antivirus warnings.
5. Before the first release, run the released executable in Windows Sandbox, a clean Windows with no Node. Download it inside the Sandbox, so SmartScreen sees it as a new download. Phase 0 [step 12](../roadmap/phase-0/12-close-out.md) does this.

## Results

Each build ran from a folder in `Downloads` and exited with code 0. The SDK build was a test only, and its dependencies were not committed. It started an MCP server and client over an in-memory transport, listed and called one tool, and ran `generateText` from the AI SDK against a mock model. esbuild printed no warnings for either SDK.

| Build | Size | Runs outside the repo | Runs in Windows Sandbox | Antivirus and SmartScreen | Notes |
| --- | --- | --- | --- | --- | --- |
| Hello-world | 105,442,632 bytes | Yes | Not yet | Defender found nothing. SmartScreen not tested, because a local copy has no download mark | |
| With the MCP SDK and the AI SDK | 107,501,384 bytes | Yes | Not yet | Defender found nothing. SmartScreen not tested | `@modelcontextprotocol/sdk` 1.32.1, `ai` 7.0.146, and `zod` 4.6.7. The bundle is 2,058,635 bytes |
| `core-v0.1.0` release, built by CI | 105,462,088 bytes | Yes | Not yet | SmartScreen blocked it on its first run | Downloaded from the GitHub release. Its SHA-256 matched `checksums.txt`. Started from File Explorer, its console window opened and closed at once, because it prints one line and exits |

Date checked: 2026-10-20, on Windows 10 with Node 26.12.0. The release download: 2026-10-21.
