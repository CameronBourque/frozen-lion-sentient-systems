# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). A debt doesn't block a roadmap step unless the step says so.

Add each new debt as a file, and list it in a table of File and Debt, in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [optional-reason.md](optional-reason.md) | A setting that makes the `reason` field optional on the action tools, to save output tokens |
| [state-sections.md](state-sections.md) | A `sections` argument on `get_state`, so a model re-reads only the sections an action changed |
| [governor-tree.md](governor-tree.md) | The governor tree reader that no MCP tool serves, and whether to serve or delete it |
| [test-only-exports.md](test-only-exports.md) | Helpers that bridge files export only for their tests, and a lint check for new ones |
