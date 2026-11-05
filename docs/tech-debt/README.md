# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). A debt doesn't block a roadmap step unless the step says so.

Add each new debt as a file with a row in the table, in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [comment-cleanup.md](comment-cleanup.md) | Trim the long headers and examples out of the old code comments |
| [comment-lint.md](comment-lint.md) | Make lint check the comment rules beyond line length |
