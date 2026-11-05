# Check doc paths outside links

Make `npm run check-docs` catch a path to a doc that no longer exists when the path is written in a backtick, in link text, or in a code comment, so a file move can't leave one behind.

## Now

- `npm run check-docs` checks each Markdown link: the file or folder must exist, and the `#anchor` must match a heading. See `scripts/check-docs/src/links.mjs`.
- It doesn't read paths outside a link's target. When the findings moved into topic folders, the check passed while these still named the old files:
  - link text, such as `[findings/game-state.md](../../findings/state/state.md)`,
  - paths in backticks in the roadmap steps, such as `findings/actions-end-turn.md`,
  - paths in the comments of `.ts` and `.lua` files and in `ci.yml`, such as `docs/findings/tuner-protocol.md`.
- A search for the old names found them, and the move fixed them by hand.

## Proposal

Add a check that finds a repo path to a doc in the text of a Markdown file and in code comments, and reports the ones that don't exist:

- In Markdown, read backtick spans and link text.
- In code, read `//`, `--`, and `#` comments in `.ts`, `.lua`, and `.yml` files.
- Match a path that starts with `docs/` or `findings/`, or ends with `.md` after a folder, and resolve it from the repo root or from `docs/`.
- If the path has a `#anchor`, check it as the link check does.

Leave a bare file name, such as `game-api.md`, alone, because it has no folder to resolve from.

## Questions

1. Should the check also read the link text, or only backticks and comments? Link text is for readers, and a mismatch with the target is a stale name, not a broken path.
2. Which roots count when a path has no `docs/` prefix: the repo root, `docs/`, or the file's own folder?
3. Should code comments be checked here, or in the lint with the other comment rules, in `scripts/comment-rules/`?

## Done when

- `npm run check-docs` fails on a backtick path or a comment path that points to a doc that doesn't exist.
- The check has tests for a path that exists, one that doesn't, and a bare file name.
- [rules/docs.md](../rules/docs.md#automated-check) lists the check.
