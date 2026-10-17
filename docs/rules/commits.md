# Commit rules

Commits and pull request titles follow the Conventional Commits format. release-please reads them to bump versions and write changelogs. How versions work is in [design/versioning.md](../design/versioning.md).

## Pull request titles

Pull requests are squash-merged, and the PR title becomes the commit message. The `pr-title` check enforces the format below on every PR title.

When a change touches one package, use it as the scope, for example `feat(core): add tuner client`.

## Types and bumps

| Commit | Bump |
| --- | --- |
| `fix: ...` | PATCH |
| `feat: ...` | MINOR |
| `feat!: ...`, or a `BREAKING CHANGE:` footer | MAJOR |
| `docs: ...`, `chore: ...`, `test: ...` | None |

Changes to prompts and knowledge files use `fix:`, because they change how agents play.
