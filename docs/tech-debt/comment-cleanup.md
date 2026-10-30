# Comment cleanup

Older comments break the comment rules in [code.md](../rules/code.md#comments), and no lint rule stops new ones. Agents copy what they read, so the old style keeps coming back. See the [tech debt index](README.md).

## Now

- 37 files in `packages/core/mod/Scripts/` and `UI/` have an `Example:` block in a comment.
- 1,206 Lua comment lines and 598 TypeScript and JavaScript comment lines are over 80 columns, counting a tab as 4.
- Many comments describe a data shape, which [schema-single-source.md](schema-single-source.md) moves into the schemas.

## Proposal

1. Delete the `Example:` blocks. Where an example shows something a test doesn't, add the test.
2. Rewrap comments to 80 columns.
3. Turn on `@stylistic/max-len` in `eslint.config.js` for comments, at 80 columns.
4. Add a check for Lua comments, such as a rule in `scripts/check-docs/` or a `luacheck` setting.

## Questions

1. Does this run before or with [schema-single-source.md](schema-single-source.md)? Both edit the same comments, so one pass may be shorter.
2. Is `luacheck` worth a new dev tool, or is a short script enough?

## Done when

- No comment has an `Example:` block.
- `npm run lint` fails on a comment line over 80 columns, in Lua and TypeScript.
