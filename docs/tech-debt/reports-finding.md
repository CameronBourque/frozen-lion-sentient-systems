# Reports finding

`docs/findings/state/reports.md` holds three tabs of the Reports screen in one file, and it is 9 characters under the length limit, so the next fact added to it fails the docs check.

## Now

The file is 124 lines and 11,991 characters. [rules/docs.md](../rules/docs.md#structure) sets the limit at 12,000, and a file over it splits by topic.

It has one `##` section of each kind for all three tabs. `## What we know now` has a `###` section for each tab:

| Section | Characters | Code it covers |
| --- | --- | --- |
| Yields tab | 5,326 | `SentientSystemsCore_StatePlayerIncome.lua` |
| Resources tab | 2,460 | `SentientSystemsCore_StatePlayerResources.lua` |
| City Status tab | 1,033 | The growth rate, war weariness, and governor in `SentientSystemsCore_StateCities.lua` |

`## Questions` has one question, on the Yields tab. `## Method` has one step for each tab, and `## Results` one bullet for each tab, plus one for the per-city rows of the Yields tab.

Three docs link to the file: the `docs/findings/state/` index, `docs/findings/state/player.md`, and `docs/roadmap/phase-1/done/state.md`.

## Proposal

Make `docs/findings/state/reports/*` a folder with a `README.md` index and one finding for each tab, named after the tab. Nothing moves into an existing finding.

## Tasks

1. Add `docs/findings/state/reports/README.md*` with the summary of the Reports screen and a row for each tab. Add `docs/findings/state/reports/yields.md*` with the Yields tab's facts, its question, its method step, and its two results.

   Replace the Yields tab in `reports.md` with a link, and add the folder's row to the `docs/findings/state/` index.
2. Add `docs/findings/state/reports/resources.md*` with the Resources tab, and replace that tab in `reports.md` with a link.
3. Add `docs/findings/state/reports/city-status.md*` with the City Status tab. Point the links in `player.md` and `docs/roadmap/phase-1/done/state.md` at the new files, delete `reports.md` and its index row, and delete this file and its row.

Each new finding has the status line, the sections, and the "Date checked" line of a finding, with the status and dates of the facts it takes.

## Done when

`reports.md` is gone. The `reports/` folder has an index and one finding for each tab, each under the length limit, and every link points at the new files. The docs check passes.
