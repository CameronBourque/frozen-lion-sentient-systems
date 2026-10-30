# Comment cleanup

Older comments break the comment rules in [code.md](../rules/code.md#comments), and no lint rule stops new ones. Agents copy what they read, so the old style keeps coming back. See the [tech debt index](README.md).

## Now

- 1,206 Lua comment lines and 598 TypeScript and JavaScript comment lines are over 80 columns, counting a tab as 4.
- Many comments describe a data shape or hold an `Example:` block. [schema-single-source.md](schema-single-source.md) removes those first, so this debt rewraps only the comments that remain.

## Proposal

1. Rewrap comments to 80 columns.
2. Turn on `@stylistic/max-len` in `eslint.config.js` for comments, at 80 columns.
3. Add a check for Lua comments, such as a rule in `scripts/check-docs/` or a `luacheck` setting.

## Questions

1. Does this run before or with [schema-single-source.md](schema-single-source.md)? Answered: after it, because that debt deletes many of the comments this one would rewrap.
2. Is `luacheck` worth a new dev tool, or is a short script enough?

## Done when

- `npm run lint` fails on a comment line over 80 columns, in Lua and TypeScript.
