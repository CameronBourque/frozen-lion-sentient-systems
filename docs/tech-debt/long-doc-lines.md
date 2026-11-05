# Long doc lines

Many docs hold paragraphs, bullets, and table rows of thousands of characters, and long lines let large files pass the 150-line limit. No rule or check limits either.

## Now

A line is a paragraph, a bullet, or a table row, and its length leaves out link targets. `scripts/check-docs/` reads 129 Markdown files. 18 of them have a line over 300 characters, 47 lines in all, and 4 lines pass 600.

[roadmap/phase-1/README.md](../roadmap/phase-1/README.md) has the longest line, at 857 characters. No file passes 12,000 characters.

`scripts/check-docs/src/length.mjs` warns about long lines and large files, but doesn't fail on them.

## Proposal

No line passes 300 characters, not counting link targets, and no file passes 12,000, counting them. The limits apply to every file the check reads, except `packages/core/CHANGELOG.md`, which release-please writes.

Table rows and findings get the same line limit. A reason over 300 characters holds more than one thought, so the row keeps a short reason and links to the text that explains it. A long result row becomes a list, and each item keeps its date and source.

A file over the size limit splits by topic. A design file becomes a folder with a `README.md` index. A finding splits into new findings in its own topic folder, each with its own status line and sections.

A split moves the text unchanged, and a later commit shortens the lines, so each diff holds one kind of change.

## Tasks

1. **Checks.** In `scripts/check-docs/src/length.mjs`, warn on a line over 300 characters and a file over 12,000, with tests. State both limits in [rules/docs.md](../rules/docs.md#structure) and its check section. Commit: `chore: warn on long doc lines and large doc files`.
2. **Core mod folder.** Move `in-game-lua.md` into the files below, unchanged. Each file gets the Decisions rows that explain it. Update the core index and every link and doc path to `in-game-lua.md`, in docs and code comments. Commit: `docs: split the core mod design into a folder`.
   - `docs/design/core/mod/README.md`: the summary, the index, the checkpoint ID, and the Civilopedia lookup.
   - `docs/design/core/mod/lines.md`: tagged lines, turn events, resync, the load line, the load signal, the version report, and errors.
   - `docs/design/core/mod/json.md`: the JSON encoder and the stash.
   - `docs/design/core/mod/state.md`: the state serializer and `SentientSystems_GetState`.
   - `docs/design/core/mod/choices.md`: the choices and placement.
   - `docs/design/core/mod/trees.md`: the tech, civic, and governor trees.
   - `docs/design/core/mod/actions.md`: the action API.
3. **Core mod lines.** Shorten the long lines in `docs/design/core/mod/`. If `actions.md` still passes 12,000 characters, make it a folder with one file per group of actions. Commit: `docs: shorten the lines in the core mod design`.
4. **Choices split.** Split `choices.md` by its `###` sections into the files below, and remove `choices.md`. Commit: `docs: split the choices finding by topic`.
   - `docs/findings/choices/production.md`: units, buildings, projects, and other modes.
   - `docs/findings/choices/districts.md`: districts, so that the production file stays under 12,000 characters.
   - `docs/findings/choices/purchases.md`: purchases and tile purchases.
   - `docs/findings/choices/research.md`: techs, civics, and the trees.
   - `docs/findings/choices/placement.md`: placement tiles.
5. **Unit orders split.** Move the builder jobs, formations, air moves, and attacks into `builder-jobs.md`, `formations.md`, `air-moves.md`, and `attacks.md` in `docs/findings/actions/`. Commit: `docs: split the unit orders finding by topic`.
6. **State split.** Move the end-turn blockers into `docs/findings/state/end-turn-blockers.md`, and the rival cities and rival units into `docs/findings/state/rivals.md`. Commit: `docs: split the state finding by topic`.
7. **Player split.** Move the Yields, Resources, and City Status tabs into `docs/findings/state/reports.md`, and the Era Progress panel into `docs/findings/state/eras.md`. Commit: `docs: split the player finding by topic`.
8. **Governors split.** Move the governor choice into `docs/findings/choices/governors.md`, and the governor tree and the Secret Societies into `docs/findings/choices/governor-tree.md`. Keep the state section in `governors.md`. Commit: `docs: split the governor choices from the governor state`.
9. **Choices lines.** Shorten the long lines in `docs/findings/choices/`. Commit: `docs: shorten the lines in the choices findings`.
10. **State lines.** Shorten the long lines in `docs/findings/state/`. Commit: `docs: shorten the lines in the state findings`.
11. **Actions lines.** Shorten the long lines in `docs/findings/actions/`. Commit: `docs: shorten the lines in the action findings`.
12. **Other findings lines.** Shorten the long lines in the lua, tuner, and top-level findings. Split out `docs/findings/tuner/printing.md` and `docs/findings/lua/dialect.md`, so `commands.md` and `contexts.md` are under 12,000. Commit: `docs: shorten the lines in the other findings`.
13. **Design lines.** Shorten the long lines in `docs/design/`, outside the core mod folder. Commit: `docs: shorten the lines in the design docs`.
14. **Other lines.** Shorten the long lines in `docs/roadmap/`, `docs/rules/`, `docs/risks.md`, `docs/overview.md`, and the package READMEs. Commit: `docs: shorten the lines in the other docs`.
15. **Fail.** Make both checks fail instead of warn, and update [rules/docs.md](../rules/docs.md#automated-check) to match. Delete this file and its row in the tech-debt index. Commit: `chore: fail on long doc lines and large doc files`.

Each split updates the links to the moved text and its folder's index.

## Done when

- No line passes 300 characters, and no file passes 12,000 characters, in every file the check reads except the changelog.
- The checks fail on a longer line or a larger file, and their tests cover both.
- [rules/docs.md](../rules/docs.md#automated-check) states both limits.
