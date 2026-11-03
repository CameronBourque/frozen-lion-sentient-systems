# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). Every debt here is fixed before [phase 1 step 7](../roadmap/phase-1/07-action-api.md) starts.

The table lists the files in the order to work on them. A later debt can depend on an earlier one, as its file says.

| File | Debt |
| --- | --- |
| [stash-readers.md](stash-readers.md) | Six readers wrap `readStash` only to rename its result |
| [schema-contract-fixtures.md](schema-contract-fixtures.md) | The TypeScript schema tests copy fixtures by hand. Fixtures from the Lua tests replace them |
| [schema-single-source.md](schema-single-source.md) | Each state and choice shape is written in up to five places. The zod schema becomes the only one |
| [comment-cleanup.md](comment-cleanup.md) | Older comments break the comment rules, and no lint rule stops new ones |
| [feature-touch-points.md](feature-touch-points.md) | A new state section or choice touches 13 places |
