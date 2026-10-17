# Bridge

The bridge is one TypeScript program that connects to the game over FireTuner, runs the agent loop through an MCP server, calls the model, and stores agent memory. It ships as a single executable.

- **Tuner client.** It connects to the FireTuner socket, which the game opens when `EnableTuner` is `1` in `AppOptions.txt`. It sends Lua to run and reads console output. The protocol has no official documentation. The community reverse-engineered it. See [findings/tuner-protocol.md](../../findings/tuner-protocol.md).
- **Resync on connect.** When the bridge starts or reconnects, it asks the game whose turn it is. Events cover everything after that. Without this step, a bridge restart in the middle of a turn misses the turn-start event.
- **Version check on connect.** The bridge and the core mod share one version and release together. When the bridge connects, the core mod reports its version. On a mismatch, the bridge asks the user to update, then downloads the GitHub release that matches the core mod. If that release is missing, it offers the newest release with the same MAJOR version. It verifies the download, replaces itself, and restarts. Resync on connect makes the restart safe in the middle of a session. Feature mod checks are in [versioning.md](../versioning.md#runtime-checks).
- **MCP server.** It exposes the action API and lookup as tools to the agent loop.
- **Tool reference.** A script generates `docs/reference/tools.md` from the MCP tool schemas. A `pull_request` workflow keeps it current in two jobs. The first job installs packages, runs the script, and uploads the file as an artifact, with no app token. The second job commits the file to the PR branch with the release app token and never runs `npm`. Dependabot PRs skip the second job, because workflows that Dependabot triggers can't read repository secrets.
- **Model client.** It calls the configured provider through one interface, the Vercel AI SDK, so any provider works. `models.yaml` maps each provider and operation to a model. Testing fills that table.
- **Memory store.** It reads and writes each agent's memory files and snapshots them under the current checkpoint ID. See [memory.md](../memory.md).
- **Logs.** The mod config file sets the log level: off, decisions only, or full. Full logs include every prompt and response. Each game writes its own log file.
- **Settings.** The bridge stores the API key in its own config. The key never goes into a game setup parameter, because saves and multiplayer games share those.

TypeScript has the reference MCP SDK and compiles to a single executable, so users download one file. The agent and advisor features are modules in the same codebase, not plugins. [findings/build-tooling.md](../../findings/build-tooling.md) tracks the build tool choice.

## Decisions

| Decision | Reason |
| --- | --- |
| The bridge is one TypeScript program, with no plugin system | TypeScript has the reference MCP SDK and builds a single executable. Two consumers do not justify plugins |
| Any LLM provider, through one interface | Users bring their own provider. Testing decides which models are good enough |
| Resync and version check when the bridge connects | A restart can miss events, and the mod and bridge update separately |
| Log levels set in the mod config file | Full logs can be large |
| Generate the tool reference from the tool schemas, and commit it | Each tool fact has one home, in the code. The model reads the same descriptions, so one text serves both. A tool change shows as a doc diff in its pull request |
| Regenerate the tool reference in a two-job `pull_request` workflow that pushes with the release app token | PR code never runs where the token is. Pushes with an app token re-run the required checks, and the release app already has write access. Separate jobs also leave room for later jobs with other dependencies |
| The bridge updates itself to the mod's version, after the user agrees | Nontechnical users should not install updates by hand. A matching version beats the latest one |
