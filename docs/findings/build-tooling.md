# Build tooling

Status: confirmed. The released executable runs in Windows Sandbox, a clean Windows with no Node, and passes the bridge's checks against a running game. SmartScreen blocks its first run from File Explorer after a download.

The bridge ships as one executable that Node SEA builds. [design/core/toolchain.md](../design/core/toolchain.md#decisions) says why. The release workflow runs `npm ci` at the repo root and `npm run build:exe` in the bridge workspace on a `windows-latest` runner, then checksums and uploads every file in `dist/`. `build:exe` must therefore leave only the executable in `dist/`.

## Questions

None open.

## What we know now

| Item | Value | Status | Source |
| --- | --- | --- | --- |
| Build command | `node --build-sea sea-config.json` builds the executable in one command on Node 26. `packages/core/bridge/scripts/build-exe.mjs` runs it after esbuild | Confirmed on Node 26.12.0 | Local build, 2026-10-20 |
| Bundling | A SEA runs one script, so esbuild bundles `src/main.ts` and every dependency into one CommonJS file, `build/main.cjs`, first | Confirmed with esbuild 0.28.2 | Local build, 2026-10-20 |
| Output folder | `--build-sea` does not create the output folder. It fails with "no such file or directory", so the build script creates `dist/` first | Confirmed | Local build, 2026-10-20 |
| Signature | The output is unsigned. `--build-sea` needs no extra step for the signature of the Node binary, and it prints no warning about it | Confirmed | `Get-AuthenticodeSignature` reports `NotSigned`, 2026-10-20 |
| Size | About 105 MB. Almost all of it is the Node runtime. The MCP SDK and the AI SDK add about 2 MB | Confirmed | [Results](#results) |
| SmartScreen | Blocks the released executable the first time it runs from File Explorer after a download. The dialog says "Windows protected your PC" and shows only **Don't run**, beside a **More info** link. **More info** adds a **Run anyway** button, which starts it. Started from PowerShell, it runs with no prompt. The executable is unsigned and has no download history | Confirmed | `core-v0.1.0` download on Windows 10, 2026-10-21. `core-v0.2.0` in Windows Sandbox, 2026-10-23 |
| Browser download | Edge warns that the file "isn't commonly downloaded" and holds it. **Keep**, in the download's menu, saves it after a second warning | Confirmed, Edge only | `core-v0.2.0` in Windows Sandbox, 2026-10-23 |

## Method

1. Build a hello-world `main.ts` into an executable.
2. Add one real dependency, the MCP SDK, and build again.
3. Copy each executable to a folder outside the repo, such as `Downloads`, and run it there.
4. Record the size and any antivirus warnings.
5. Run the released executable in Windows Sandbox, a clean Windows with no Node. Download it inside the Sandbox, so SmartScreen sees it as a new download. The `core-v0.2.0` row in [Results](#results) is this check.

## Results

Each build ran from a folder in `Downloads` and exited with code 0. The SDK build was a test only, and its dependencies were not committed. It started an MCP server and client over an in-memory transport, listed and called one tool, and ran `generateText` from the AI SDK against a mock model. esbuild printed no warnings for either SDK.

| Build | Size | Runs outside the repo | Runs in Windows Sandbox | Antivirus and SmartScreen | Notes |
| --- | --- | --- | --- | --- | --- |
| Hello-world | 105,442,632 bytes | Yes | Not tested | Defender found nothing. SmartScreen not tested, because a local copy has no download mark | |
| With the MCP SDK and the AI SDK | 107,501,384 bytes | Yes | Not tested | Defender found nothing. SmartScreen not tested | `@modelcontextprotocol/sdk` 1.32.1, `ai` 7.0.146, and `zod` 4.6.7. The bundle is 2,058,635 bytes |
| `core-v0.1.0` release, built by CI | 105,462,088 bytes | Yes | Not tested | SmartScreen blocked it on its first run | Downloaded from the GitHub release. Its SHA-256 matched `checksums.txt`. Started from File Explorer, its console window opened and closed at once, because it prints one line and exits |
| `core-v0.2.0` release, built by CI | 105,478,984 bytes | Yes | Yes. Started from PowerShell and from File Explorer, it printed its banner and kept waiting for the tuner, because the Sandbox has no game | Edge warned at download. SmartScreen blocked it from File Explorer, and **More info** then **Run anyway** started it. No prompt from PowerShell. Defender found nothing | SHA-256 matched `checksums.txt` in the Sandbox and on the game machine. On the game machine, against a single-player game: started mid-turn, it logged `connected to the tuner`, `core version 0.2.0`, and `turn 0`. Ending the turn logged `turn 0` when the turn came back. A restart in the same turn logged the version and `turn 0` again, without ending the turn. Started at the main menu, it warned that `SentientSystemsCore_UI` wasn't loaded, logged `core loaded` when a game loaded, reconnected when the load dropped the connection, and logged the version and `turn 0` |

Date checked: 2026-10-20, on Windows 10 with Node 26.12.0. The `core-v0.1.0` download: 2026-10-21. The `core-v0.2.0` download, in Windows Sandbox and on the game machine: 2026-10-23.
