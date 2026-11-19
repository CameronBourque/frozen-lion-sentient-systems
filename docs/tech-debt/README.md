# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). A debt doesn't block a roadmap step unless the step says so.

Add each new debt as a file, and list it in a table of File and Debt, in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [move-river-reason.md](move-river-reason.md) | A move whose path starts with a river crossing is refused as having no route, though the game would take it over more turns |
| [optional-reason.md](optional-reason.md) | A setting that makes the `reason` field optional on the action tools, to save output tokens |
| [state-sections.md](state-sections.md) | A `sections` argument on `get_state`, so a model re-reads only the sections an action changed |
| [action-changes.md](action-changes.md) | Action results that carry the records the action changed, so a model needs no state read after it |
