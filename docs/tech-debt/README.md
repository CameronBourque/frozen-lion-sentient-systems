# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). A debt doesn't block a roadmap step unless the step says so.

Add each new debt as a file, and list it in a table of File and Debt, in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [action-bodies.md](action-bodies.md) | Each action's whole body is an anonymous function passed to `RunAction`, so the long ones can't be split by step |
| [duplicated-code.md](duplicated-code.md) | The same function, constant, or test setup is written out in several files of the Lua mod and the bridge |
| [nested-objects.md](nested-objects.md) | A pair such as `x` and `y` is written out inline in many schemas and signatures, and objects nest inside objects with no name |
