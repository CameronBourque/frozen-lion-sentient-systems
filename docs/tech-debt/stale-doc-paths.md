# Check doc paths outside links

Make a path to a doc that no longer exists fail the build when the path is written in a backtick, in link text, or in a code comment, so a file move can't leave one behind.

## Now

- `npm run check-docs` checks each Markdown link: the file or folder must exist, and the `#anchor` must match a heading. See `scripts/check-docs/src/links.mjs`.
- It doesn't read paths outside a link's target. When the findings moved into topic folders, the check passed while these still named the old files:
  - link text, such as `[findings/game-state.md](../../findings/state/state.md)`,
  - paths in backticks in the roadmap steps, such as `findings/actions-end-turn.md`,
  - paths in the comments of `.ts` and `.lua` files and in `ci.yml`, such as `docs/findings/tuner-protocol.md`.
- A search for the old names found them, and the move fixed them by hand.
- Unfinished roadmap steps name docs they will create, such as `docs/reference/tools.md`, so a plain existence check would fail on correct text.

## Proposal

One resolver in `scripts/`, used by two checks. Each finds a doc path in text and reports the ones that don't exist:

- `check-docs` reads backtick spans and link text in Markdown.
- `comment-rules` reads `//`, `--`, and `#` comments in `.ts`, `.lua`, and `.yml` files, as lint.

A path is a doc path when it starts with `docs/` or `findings/` and ends in `.md`, with an optional `#anchor` that is checked as the link check does. It resolves from the repo root, then from `docs/`. A bare file name, such as `game-api.md`, and any other folder, such as `packages/`, are left alone.

A doc that doesn't exist yet is written from `docs/` with a trailing `*`, such as `docs/reference/tools.md*`. The check skips the existence test for it, and fails if the file exists, so the `*` can't outlive the step that creates the file.

## Tasks

1. **Resolver.** Add the shared module that finds doc paths in a line of text, resolves them, and handles the `*`, with tests for a path that exists, one that doesn't, a bare file name, a starred path that doesn't exist, and a starred path that does. Commit: `chore: resolve doc paths in text`.
2. **Markdown check.** Add the check to `scripts/check-docs/src/`, wired into `run.mjs`, for backtick spans and link text, with tests. Commit: `chore: check doc paths in Markdown text`.
3. **Comment rule.** Add the rule to `scripts/comment-rules/` for TypeScript and Lua comments, with tests. Commit: `chore: lint doc paths in comments`.
4. **Yml comments.** Extend the comment rule to `.yml` files, with tests. Commit: `chore: lint doc paths in yml comments`.
5. **Fix and record.** Fix the stale paths the checks find. Write `docs/` and a `*` on the planned ones. List the checks in [rules/docs.md](../rules/docs.md#automated-check) and [rules/code.md](../rules/code.md#lint-and-test), and add the `*` convention to the docs rules. Delete this file and its row in the [index](README.md). Commit: `docs: fix stale doc paths`.

## Done when

- `npm run check-docs` fails on a backtick path or a link text path that points to a doc that doesn't exist, and `npm run lint` fails on the same in a TypeScript, Lua, or yml comment.
- Both fail on a starred path whose file exists.
- The checks have tests for a path that exists, one that doesn't, a bare file name, and a starred path in each state.
- [rules/docs.md](../rules/docs.md#automated-check) and [rules/code.md](../rules/code.md#lint-and-test) list the checks.
