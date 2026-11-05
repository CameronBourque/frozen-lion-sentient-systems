# Lint the comment rules

Make lint catch the comment rules that it can't check today, so a violation fails the build instead of waiting for a review. Depends on [comment-cleanup.md](comment-cleanup.md), which makes the existing files pass.

## Now

- `npm run lint` checks the length of a comment line, in `scripts/lua-comments/` for Lua and in the `@stylistic/max-len` rule for TypeScript.
- The rest of the [comment rules](../rules/code.md#comments) have no check: the one-to-three line file header, no data shapes, no examples, and no line numbers.

## Proposal

Add checks for the rules a script can see, in the Lua script and as an ESLint rule for TypeScript:

- A file header over three lines.
- A JSON shape in a comment, such as `{"` or a quoted key followed by a colon.
- "such as" or "for example" followed by a quoted or code example.
- "line N" or "lines N to M".

These are heuristics, so each check reports a likely miss, and a comment can opt out with a short reason.

## Questions

1. Should a failed check fail the build, or only warn at first?
2. Should the tests' comments follow the same checks?

## Done when

- Lint fails on a comment that breaks one of the checked rules, in both Lua and TypeScript.
- The checks are listed in [rules/code.md](../rules/code.md#lint-and-test).
