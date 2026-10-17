# Doc rules

How docs are organized. These rules apply to every file under `docs/`, to package READMEs, and to `AGENTS.md`. How to write the sentences is in [writing.md](writing.md).

## Structure

- **One topic per file.** Aim for under 150 lines. If two files are always read together, merge them.
- **Start each file with a one- or two-sentence summary.** The folder index reuses it.
- **Every folder has a `README.md` index.** The index has one row per file or subfolder. Add each new file to its folder's index.
- **Use relative links.** Readers and tools can follow them.

## No repetition

- **Every fact has one home.** Anywhere else, link to it. Don't restate it.
- The only exception is a one-line description of what a linked doc covers. It's allowed in indexes, overviews, and package READMEs.
- When you find a duplicate, keep the most specific home and replace the other copy with a link.

Where each kind of fact lives:

| Kind of fact | Home |
| --- | --- |
| How something works | [design/](../design/README.md) |
| Why it works that way | The `## Decisions` table of that design file |
| What is true about the game or our tools, and how we checked | [findings/](../findings/README.md) |
| How to test a finding | That finding's `## Method` section |
| What to do next, and in what order | [roadmap/](../roadmap/README.md) |
| What could go wrong, and the fallback | [risks.md](../risks.md) |
| Rules | [rules/](README.md) |
| What a term means | [glossary.md](../glossary.md) |

## Decisions

- Each design file ends with a `## Decisions` table with two columns: Decision and Reason.
- When a decision changes, mark the old row as replaced and say why. Don't delete it.

## Findings

- Each finding has one of two statuses:
  - **Confirmed.** Tested in a running game, or read directly from the game's own files.
  - **Unconfirmed.** From community sources, or a guess. Test it before code depends on it.
- Each finding notes how it was checked and when.
- Link an external source at a pinned commit or release, never a branch such as `main`, so the cited lines and sections stay where the link says. Name the short commit ID in the text.
- When a test changes a finding, update it, but keep the old result. Mark it as replaced and say why.
- A finding file has these parts: a status line, `## Questions`, `## What we know now`, `## Method`, `## Results`, and a "Date checked" line.

## Roadmap

- Each phase is a folder, `roadmap/phase-N/`, with a `README.md` that holds the summary, the gate as one sentence, and a step table.
- **The step table's Status column is the only progress tracker.** Don't add checklists that repeat it. What each step must achieve lives in its "Done when".
- Before a phase is broken down, its README has a `## Scope` list of planned work. When work on the phase starts, the scope items become steps and the list is removed.
- Each step is its own file, `NN-short-name.md`, with:
  - a one-line summary and a link back to the phase,
  - `## Tasks`,
  - `## Done when`,
  - `## Record`, which says which findings or design files to update.
- Steps link to a finding's `## Method` instead of restating a test procedure.
- To close a phase:
  1. Check that every step's status is Done.
  2. Update its status in [roadmap/README.md](../roadmap/README.md).
  3. Update [risks.md](../risks.md).
  4. Move what it proved into findings or design.
  5. Delete the step files. Git keeps their history. In the phase README, replace the step table with links to the findings and design files that now hold the results.

## Risks

- [risks.md](../risks.md) lists each risk with its impact and fallback.
- An open question that a test can answer belongs in a finding's `## Questions`. The risk row links to it.
- An open design question belongs in the design file it affects.

## Automated check

`scripts/check-docs/` checks the mechanical rules in this file and in [writing.md](writing.md): links and anchors, indexes, required sections, the punctuation and word patterns, and file length. Each check is its own file there. CI runs the check and its tests on every pull request, in the `check-docs` job of `.github/workflows/docs.yml`. To run them locally, run these commands from the repo root:

```sh
node scripts/check-docs/index.mjs
node --test scripts/check-docs/checks.test.mjs
```

The check skips `writing.md` for the pattern rules, because that file quotes the patterns. It reads the inflated words and metaphor nouns from the lists in `writing.md`, so edit those lists there. Files over 150 lines get a warning, not a failure.

## Local-only docs

- A doc that must not be committed gets a note at the top that says so.
- List it in `.git/info/exclude`, which git never commits. Don't use `.gitignore`, because that file is committed.
- Don't link to it from committed docs.
