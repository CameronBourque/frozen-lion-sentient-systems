# Comment rule workarounds

The comment lint lets a file get past its three-line header limit with a blank line, and nothing checks the other comment rules that lint can't see.

## Now

- `scripts/comment-rules/src/header-rule.mjs` ends the header at the first blank line. A long comment block after one blank line is a second block, so it isn't counted.
- In the trade route and spy missions work, four files used that: `ChoicesTradeRoutes.lua`, `ChoicesSpyMissions.lua`, and the fakes `FakeGame/Trade.lua` and `FakeGame/SpyMissions.lua`. Each had a short header, a blank line, and a paragraph that the header rule would have refused.
- The two fakes' paragraphs also described the fields a fake reads from its data, which [code.md](../rules/code.md#comments) rules out. Lint can't see that, so only review caught it.
- All four are fixed. A scan of the Lua and TypeScript files found no other comment block of two or more lines after the header that stands alone, and no use of `comment-lint-ignore` outside the rule's own tests.

## Proposal

Make the header rule close the gap, and look for other ways around the comment rules.

- After the header and its blank line, a comment block has to sit directly above the code it describes, with no blank line between. A comment that stands alone near the top fails.
- Review the rules for other loopholes, such as a header that spreads over two comment blocks with a blank line between, and a shape comment that avoids the words the check looks for.

## Questions

1. Should a comment block that stands alone fail anywhere in a file, or only after the header? A section comment could be one of the cases that is allowed.
2. Is there a check that finds a comment naming a test fake's data fields? The data-shape heuristic looks for JSON, and the paragraphs above were prose.

## Done when

Lint fails on a standalone comment block after a file's header, in Lua and TypeScript, with tests for it. [code.md](../rules/code.md#lint-and-test) lists the rule, and the questions are answered in this file or in `scripts/comment-rules/`.
