# Versioning

One repository with four packages. The bridge and core mod share one version, and each feature mod has its own version plus a required core range. Commit messages decide the bumps.

## Packages

Each version has the form `MAJOR.MINOR.PATCH`.

| Package | Version |
| --- | --- |
| Bridge and core mod | One shared version. The bridge, including its agent and advisor modules, counts as part of core |
| Agent players mod | Its own version, with a required core range such as `core >=1.3 <2` |
| Advisors mod | Its own version, with a required core range |

When an agent feature needs new bridge code, core gets a MINOR bump, and the agent players mod raises its minimum core version. Both changes land in one pull request, and both packages get new versions.

## Bump rules

| Part | Bumps when | Examples |
| --- | --- | --- |
| MAJOR | A change breaks something users keep between versions, and no migration exists | Old agent memory or civ notes stop loading, the `overrides/` format changes, a config setting is removed |
| MINOR | A change adds a feature | A new tool, personality, setting, or panel |
| PATCH | A change fixes or tunes without adding a feature | A bug fix, a prompt change, a knowledge file edit |

The protocol between the core mod and the bridge does not count toward MAJOR, because both always run the same version. The core API that feature mods call does count. A change that breaks it is a MAJOR bump for core.

Memory files, civ notes, and the config file each carry their own schema version. When a format changes, the bridge migrates old files when it loads them. A format change with a migration is not breaking.

Development starts at `0.1.0`. `initial-version` in `release-please-config.json` sets each package's first release, because release-please otherwise starts a package at `1.0.0`. Below `1.0.0`, a breaking change bumps MINOR. The first public Workshop release is `1.0.0`.

## Commits

Commit messages trigger the bumps. The commit format and which type bumps which part are in [rules/commits.md](../rules/commits.md).

## Release flow

Release-please runs in manifest mode. It bumps only the packages whose files a commit touched. The bridge and the core mod live in one package folder, `packages/core`, so they always share one version.

Release-please keeps a release pull request open with the next versions and the changelogs. It rewrites that pull request only when the changelog notes change, so a change to `release-please-config.json` alone leaves the pull request as it was. To rebuild it, close the pull request, delete its branch, and run the **Release** workflow again. Merging the release pull request starts the release:

1. Release-please writes each new version into its package's `package.json`, its `.modinfo`, and a version constant in its Lua.
2. It tags each released package and creates its GitHub release.
3. If core changed, CI builds the bridge executable and publishes it to the core release with a checksum.
4. CI packages the changed mods, and they go to the Workshop.

The GitHub release always comes before the Workshop upload. Each Workshop version of the core mod then has a matching bridge release.

Each `.modinfo` holds the full version twice: in the `version` attribute on `<Mod>`, and in `<Properties><Version>`. A UI script reads the second one at runtime with `Modding.GetModProperty`. Gameplay states have no `Modding`, so they read the Lua constant. See [findings/game-api.md](../findings/game-api.md#mod-metadata).

## Runtime checks

At runtime, the bridge matches the core version exactly, as described in [core/bridge.md](core/bridge.md). Each feature mod reports its version and its required core range when it connects. If core is outside that range, the game shows a message that names the mod to update.

## Decisions

| Decision | Reason |
| --- | --- |
| One repository. The bridge and core share a version, and feature mods have their own | The bridge must match core exactly. Feature mods change on their own schedule and declare a core range. One repository keeps cross-package changes in one pull request |
| Conventional Commits and release-please decide bumps | Bumps and changelogs come from commits, with no manual step |
| Release-please opens its pull requests with a GitHub App token | A pull request opened with `GITHUB_TOKEN` starts no workflows, so the required checks would never run on the release pull request. An app token doesn't expire, unlike a personal access token |
| Dependabot titles use `fix(deps)` for dependencies the bridge ships, `chore(deps-dev)` for development tools, and `ci` for GitHub Actions | An update to what ships releases a core PATCH. Updates to development tools and Actions change nothing that ships, so they release nothing |
| Workflows use the `pull_request` event, not `pull_request_target` | The checks only read the pull request. `pull_request_target` gives more access than they need |
| The `.modinfo` holds the full `MAJOR.MINOR.PATCH` version, not a whole-number counter | The game accepts a three-part version, and saves made with it reload. The mod menu and the bridge then show the release's own version |
| Schema versions in memory, civ note, and config files | Migrations keep format changes from breaking saved games |
