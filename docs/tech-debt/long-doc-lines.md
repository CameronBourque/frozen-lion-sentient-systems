# Long doc lines

Many docs hold paragraphs and table cells of 600 to 3,300 characters on one line, and no rule or check limits them.

## Now

A line is a paragraph, a bullet, or a table row. 28 files have at least one line over 600 characters. The worst, by lines over 600:

| File | Lines over 600 | Longest |
| --- | --- | --- |
| [findings/choices/choices.md](../findings/choices/choices.md) | 11 | 976 |
| [design/core/in-game-lua.md](../design/core/in-game-lua.md) | 10 | 3,345 |
| [findings/state/governors.md](../findings/state/governors.md) | 7 | 2,062 |
| [findings/state/player.md](../findings/state/player.md) | 6 | 1,664 |
| [design/core/bridge.md](../design/core/bridge.md) | 5 | 951 |
| [findings/choices/government.md](../findings/choices/government.md) | 5 | 792 |

[design/core/in-game-lua.md](../design/core/in-game-lua.md) is the worst case. Its Action API bullet is 3,345 characters and holds six topics: the result shape, the stash, `MoveUnit`, `UnitAction` and its orders, `CityAttack`, and the builder jobs. Each action step adds to it. The state serializer paragraph (2,611) and the `GetState` paragraph are close behind.

The check in `scripts/check-docs/` warns about files over 150 lines but not about long lines.

## Proposal

1. Split each long line by topic. A bullet that holds several topics becomes a section in the file that owns the topic. The action API leaves `in-game-lua.md` for a new `design/core/actions.md`, and the bullet keeps three sentences and a link. Later action steps add sections there.
2. Where a line is one long topic, break it into short paragraphs or a list, as [writing.md](../rules/writing.md) asks for one thought per sentence.
3. Add a length check to `scripts/check-docs/`, so the lines stay short. It warns first, like the file-length check, and fails once the files are fixed.

Start with `in-game-lua.md`, because the action steps keep growing it. Then work down the table.

## Questions

- What is the limit on a line? 600 characters is the cutoff used for the counts above.
- Do table cells count the same as paragraphs? The Decisions table has a reason in most rows, and a long reason is one thought, so the limit may need to be higher for tables.
- Does a findings file get the same limit? A result row can be long because it records one measurement, and splitting it would lose its dates and sources.

## Done when

- No doc has a line over the limit, other than the files the check excludes.
- The check warns or fails on a longer line, and its tests cover it.
- [rules/docs.md](../rules/docs.md#automated-check) states the limit.
