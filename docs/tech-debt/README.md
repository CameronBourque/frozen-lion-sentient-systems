# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). A debt doesn't block a roadmap step unless the step says so.

Add each new debt as a file, and list it in a table of File and Debt, in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [nested-objects.md](nested-objects.md) | A pair such as `x` and `y` is written out inline in many schemas and signatures, and objects nest inside objects with no name |
