# Tech debt

Known debt in the code and docs, with the proposed fix for each. Each file follows [rules/docs.md](../rules/docs.md#tech-debt). The table lists the files in the order to work on them.

| File | Debt |
| --- | --- |
| [schema-single-source.md](schema-single-source.md) | Each state and choice shape is written in up to five places. The zod schema becomes the only one |
| [schema-contract-fixtures.md](schema-contract-fixtures.md) | The TypeScript schema tests copy fixtures by hand. Fixtures from the Lua tests replace them |
| [comment-cleanup.md](comment-cleanup.md) | Older comments break the comment rules, and no lint rule stops new ones |
| [feature-touch-points.md](feature-touch-points.md) | A new state section or choice touches 13 places |
| [stash-readers.md](stash-readers.md) | Six readers wrap `readStash` only to rename its result |
| [probe-scripts.md](probe-scripts.md) | Phase 0 probe scripts that only re-test answered findings |
| [fake-game-registry.md](fake-game-registry.md) | `FakeGame.lua` has a header index and a dependency check that each new feature must update |
