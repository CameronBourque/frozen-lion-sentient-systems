# Long doc lines

Many docs hold paragraphs, bullets, and table rows of thousands of characters, and long lines let large files pass the 150-line limit. No rule or check limits either.

## Now

A line is a paragraph, a bullet, or a table row. `scripts/check-docs/` reads 107 Markdown files. 71 of them have a line over 300 characters, 486 lines in all, and 93 lines pass 600.

[design/core/in-game-lua.md](../design/core/in-game-lua.md) has the longest line. Its Action API bullet is 5,729 characters and holds every action. The file has one `##` section, a list of bullets, and one Decisions table for all of them.

Eight files pass 12,000 characters, although only one passes 150 lines:

| File | Characters | Lines | Lines over 300 |
| --- | --- | --- | --- |
| [findings/choices/choices.md](../findings/choices/choices.md) | 29,225 | 137 | 43 |
| [design/core/in-game-lua.md](../design/core/in-game-lua.md) | 26,763 | 80 | 19 |
| [findings/actions/unit-orders.md](../findings/actions/unit-orders.md) | 25,712 | 134 | 36 |
| [findings/state/state.md](../findings/state/state.md) | 21,358 | 151 | 23 |
| [findings/state/player.md](../findings/state/player.md) | 18,019 | 87 | 23 |
| [findings/state/governors.md](../findings/state/governors.md) | 14,416 | 54 | 20 |
| [findings/tuner/commands.md](../findings/tuner/commands.md) | 13,127 | 114 | 11 |
| [findings/lua/contexts.md](../findings/lua/contexts.md) | 12,526 | 147 | 9 |

`scripts/check-docs/src/length.mjs` warns about files over 150 lines but not about long lines or file size.

## Proposal

No line passes 300 characters, and no file passes 12,000. The limits apply to every file the check reads, except `packages/core/CHANGELOG.md`, which release-please writes.

Table rows and findings get the same line limit. A reason over 300 characters holds more than one thought, so the row keeps a short reason and links to the text that explains it. A long result row becomes a list, and each item keeps its date and source.

A file over the size limit splits by topic. A design file becomes a folder with a `README.md` index. A finding splits into new findings in its own topic folder, each with its own status line and sections.

A split moves the text unchanged, and a later commit shortens the lines, so each diff holds one kind of change.

## Tasks

1. **Checks.** In `scripts/check-docs/src/length.mjs`, warn on a line over 300 characters and a file over 12,000, with tests. State both limits in [rules/docs.md](../rules/docs.md#structure) and its check section. Commit: `chore: warn on long doc lines and large doc files`.
2. **Core mod folder.** Move `in-game-lua.md` into the files below, unchanged. Each file gets the Decisions rows that explain it. Update the core index and every link and doc path to `in-game-lua.md`, in docs and code comments. Commit: `docs: split the core mod design into a folder`.
   - `docs/design/core/mod/README.md*`: the summary, the index, the checkpoint ID, and the Civilopedia lookup.
   - `docs/design/core/mod/lines.md*`: tagged lines, turn events, resync, the load line, the load signal, the version report, and errors.
   - `docs/design/core/mod/json.md*`: the JSON encoder and the stash.
   - `docs/design/core/mod/state.md*`: the state serializer and `SentientSystems_GetState`.
   - `docs/design/core/mod/choices.md*`: the choices and placement.
   - `docs/design/core/mod/trees.md*`: the tech, civic, and governor trees.
   - `docs/design/core/mod/actions.md*`: the action API.
3. **Core mod lines.** Shorten the long lines in `docs/design/core/mod/`. If `actions.md` still passes 12,000 characters, make it a folder with one file per group of actions. Commit: `docs: shorten the lines in the core mod design`.
4. **Choices split.** Split `choices.md` by its `###` sections into the files below, and remove `choices.md`. Commit: `docs: split the choices finding by topic`.
   - `docs/findings/choices/production.md*`: units, buildings, districts, projects, and other modes.
   - `docs/findings/choices/purchases.md*`: purchases and tile purchases.
   - `docs/findings/choices/research.md*`: techs, civics, and the trees.
   - `docs/findings/choices/placement.md*`: placement tiles.
5. **Unit orders split.** Move the builder jobs and adding production into `docs/findings/actions/builder-jobs.md*`, the attacks into `docs/findings/actions/attacks.md*`, and the air moves into `docs/findings/actions/air-moves.md*`. Commit: `docs: split the unit orders finding by topic`.
6. **State split.** Move the end-turn blockers into `docs/findings/state/end-turn-blockers.md*`, and the rival cities and rival units into `docs/findings/state/rivals.md*`. Commit: `docs: split the state finding by topic`.
7. **Player split.** Move the Yields, Resources, and City Status tabs into `docs/findings/state/reports.md*`, and the Era Progress panel into `docs/findings/state/eras.md*`. Commit: `docs: split the player finding by topic`.
8. **Governors split.** Move the governor choices into `docs/findings/choices/governors.md*`, and keep the state section in `governors.md`. Commit: `docs: split the governor choices from the governor state`.
9. **Choices lines.** Shorten the long lines in `docs/findings/choices/`. Commit: `docs: shorten the lines in the choices findings`.
10. **State lines.** Shorten the long lines in `docs/findings/state/`. Commit: `docs: shorten the lines in the state findings`.
11. **Actions lines.** Shorten the long lines in `docs/findings/actions/`. Commit: `docs: shorten the lines in the action findings`.
12. **Other findings lines.** Shorten the long lines in `docs/findings/lua/`, `docs/findings/tuner/`, and the top-level findings. Cut `commands.md` and `contexts.md` under 12,000 characters, or split one by topic if a cut loses facts. Commit: `docs: shorten the lines in the other findings`.
13. **Design lines.** Shorten the long lines in `docs/design/`, outside the core mod folder. Commit: `docs: shorten the lines in the design docs`.
14. **Other lines.** Shorten the long lines in `docs/roadmap/`, `docs/rules/`, `docs/risks.md`, `docs/overview.md`, and the package READMEs. Commit: `docs: shorten the lines in the other docs`.
15. **Fail.** Make both checks fail instead of warn, and update [rules/docs.md](../rules/docs.md#automated-check) to match. Delete this file and its row in the tech-debt index. Commit: `chore: fail on long doc lines and large doc files`.

Each split updates the links to the moved text and its folder's index.

## Done when

- No line passes 300 characters, and no file passes 12,000 characters, in every file the check reads except the changelog.
- The checks fail on a longer line or a larger file, and their tests cover both.
- [rules/docs.md](../rules/docs.md#automated-check) states both limits.
