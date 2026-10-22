# Bridge

The bridge is one TypeScript program that connects to the game over FireTuner, runs the agent loop through an MCP server, calls the model, and stores agent memory. It ships as a single executable.

- **Tuner client.** It connects to the FireTuner socket, which the game opens when `EnableTuner` is `1` in `AppOptions.txt`. It sends Lua to run and reads console output. The protocol has no official documentation. The community reverse-engineered it, and phase 0 confirmed it. See [findings/tuner-protocol.md](../../findings/tuner-protocol.md) and [findings/tuner-commands.md](../../findings/tuner-commands.md). The client is three layers in `src/tuner/`. `framing.ts` turns bytes into frames. `connection.ts` holds the socket and reconnects with backoff. `client.ts` does the handshake, finds Lua states by name, and runs Lua. It sends one request at a time, and wraps each command in the marker wrapper from `wrapper.ts`. Only lines between a command's markers, from the command's own state, are its result. Every other print goes out as an `output` event.
- **Tagged lines.** `src/events.ts` turns the core mod's [tagged lines](in-game-lua.md) into typed events, such as `{ type: "turn", playerId: 0 }`. `src/main.ts` strips the state name from each `output` line, parses it, and logs the event. A line without the tag comes from the game or another mod, and the bridge ignores it. A tagged line with an unknown kind or bad arguments gets a warning in the log. The core version line comes back in the lines of a `run()` call, not as an `output` event.
- **Resync on connect.** When the bridge starts or reconnects, it asks the game whose turn it is. Events cover everything after that. Without this step, a bridge restart in the middle of a turn misses the turn-start event.
- **Version check on connect.** The bridge and the core mod share one version and release together. When the bridge connects, the core mod reports its version. On a mismatch, the bridge asks the user to update, then downloads the GitHub release that matches the core mod. If that release is missing, it offers the newest release with the same MAJOR version. It verifies the download, replaces itself, and restarts. Resync on connect makes the restart safe in the middle of a session. Feature mod checks are in [versioning.md](../versioning.md#runtime-checks).
- **MCP server.** It exposes the action API and lookup as tools to the agent loop.
- **Tool reference.** A script generates `docs/reference/tools.md` from the MCP tool schemas. A `pull_request` workflow keeps it current in two jobs. The first job installs packages, runs the script, and uploads the file as an artifact, with no app token. The second job commits the file to the PR branch with the release app token and never runs `npm`. Dependabot PRs skip the second job, because workflows that Dependabot triggers can't read repository secrets.
- **Model client.** It calls the configured provider through one interface, the Vercel AI SDK, so any provider works. `models.yaml` maps each provider and operation to a model. Testing fills that table.
- **Memory store.** It reads and writes each agent's memory files and snapshots them under the current checkpoint ID. See [memory.md](../memory.md).
- **Logs.** `src/log.ts` prints each log line with the local time in front, and prints warnings to stderr. The mod config file will set the log level: off, decisions only, or full. Full logs include every prompt and response. Each game writes its own log file.
- **Settings.** The bridge stores the API key in its own config. The key never goes into a game setup parameter, because saves and multiplayer games share those.

TypeScript has the reference MCP SDK and compiles to a single executable, so users download one file. The agent and advisor features are modules in the same codebase, not plugins. [findings/build-tooling.md](../../findings/build-tooling.md) tracks the executable build. The TypeScript setup is in [rules/code.md](../../rules/code.md#typescript).

## Decisions

| Decision | Reason |
| --- | --- |
| The bridge is one TypeScript program, with no plugin system | TypeScript has the reference MCP SDK and builds a single executable. Two consumers do not justify plugins |
| Any LLM provider, through one interface | Users bring their own provider. Testing decides which models are good enough |
| Resync and version check when the bridge connects | A restart can miss events, and the mod and bridge update separately |
| Log levels set in the mod config file | Full logs can be large |
| Generate the tool reference from the tool schemas, and commit it | Each tool fact has one home, in the code. The model reads the same descriptions, so one text serves both. A tool change shows as a doc diff in its pull request |
| Regenerate the tool reference in a two-job `pull_request` workflow that pushes with the release app token | PR code never runs where the token is. Pushes with an app token re-run the required checks, and the release app already has write access. Separate jobs also leave room for later jobs with other dependencies |
| Node 26 for development, CI, and the executable | The executable ships with the Node version that builds it, so that version must be a supported LTS release. Node 26 is the LTS release with the longest support, and it builds the executable with `node --build-sea` |
| The bridge is an npm workspace of the root package | One lockfile and one `npm ci`, so CI's tests can import the bridge's packages. The bridge and `typescript-eslint` share one TypeScript |
| `tsx` runs TypeScript in development | It allows enums and other TypeScript features that Node's built-in type stripping can't run, which keeps code organized |
| `tsc` only type-checks, as its own CI job | `tsx`, Vitest, and esbuild don't check types. Nothing uses compiled output, because esbuild bundles the release from `src/` |
| ES modules, with no namespaces | Modules are standard JavaScript, fit one file per concern, show each file's dependencies, and let esbuild drop unused code |
| typescript-eslint `recommended`, plus the promise, `no-unsafe-*`, and error rules | An unawaited promise fails silently in socket code. Data typed `any` from the socket must get a checked type before code uses it |
| Node SEA builds the executable | It runs on the same Node as development and tests. Bun would ship a second runtime, so a bug could appear only in the release |
| Build the executable on a `windows-latest` runner, as a one-entry matrix | The build machine matches the target. A later platform is one more matrix entry |
| The bridge updates itself to the mod's version, after the user agrees | Nontechnical users should not install updates by hand. A matching version beats the latest one |
| The tuner client has three layers: framing, connection, and client | Each layer is tested on its own. Framing does no input or output, and the connection knows framing but not the protocol |
| Each command runs inside the marker wrapper | Replies carry no request ID, and an unprompted print looks the same as a command's output. The markers tie each line to its command. The wrapper is one expression, so it runs whichever way the game runs a command |
| One request at a time, through one queue | Replies carry no request ID. A round trip takes 18 to 54 ms, which is small next to a model call |
| A request that times out keeps the socket open, and its late reply is dropped | Replies always come back in order. A load holds every reply for about a minute, so dropping the socket on each timeout would reconnect over and over |
| The client keeps the state list for each connection, and lists the states again after `ERR:Invalid Lua State` or a `ContextPtr:GetID()` mismatch | A load resets the socket, which clears the list. A quit to the main menu keeps the socket open, so the client catches a stale index when a command uses it |
| The bridge reads a tagged line from any Lua state | A list of allowed states would need upkeep for each new script. Anything else the bridge needs goes into a tagged line where it can. An untagged game line that the bridge must read is an exception |
| A tagged line that doesn't parse logs a warning | A core mod newer than the bridge, or a Lua bug such as a `nil` player ID, shows in the log. Without it, an agent would never act and nothing would say why |
| Reconnect with backoff, from 500 ms up to 10 s | The game may not be running yet. After a crash it listens again under a new process, and the bridge should find it without a restart |
