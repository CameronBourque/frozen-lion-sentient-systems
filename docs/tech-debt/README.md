# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). A debt doesn't block a roadmap step unless the step says so.

Add each new debt as a file, and list it in a table of File and Debt, in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [action-bodies.md](action-bodies.md) | Each action's whole body is an anonymous function passed to `RunAction`, so the long ones can't be split by step |
| [thin-lua-helpers.md](thin-lua-helpers.md) | Some Lua helpers only forward to another function, and others are copied into several files |
