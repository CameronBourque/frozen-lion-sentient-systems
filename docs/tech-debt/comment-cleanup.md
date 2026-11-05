# Trim the old code comments

Cut the long file headers and the examples out of the code comments that were written before the [comment rules](../rules/code.md#comments).

## Now

- 40 of the 132 Lua files in `packages/core/mod/` start with a header of four to nine lines. The rule is one to three.
- 30 of the 50 TypeScript files in `packages/core/bridge/src/` start with a header over three lines, and about 28 comments there give an example with "such as" or "for example".
- `packages/core/bridge/test/tuner/fake-game.ts` has a six-line header.
- The comment length is checked by lint. Nothing else is.

## Proposal

Go folder by folder, one commit each: trim each header to its purpose, link the doc that holds the details, and turn an example in a comment into a test or drop it. Don't change code.

## Questions

1. Which folder first? The state and choices folders hold most of the Lua headers.

## Done when

- No source file starts with a comment over three lines, and no comment gives an example that a test could hold.
- `npm run lint` and `npm run coverage` pass.
