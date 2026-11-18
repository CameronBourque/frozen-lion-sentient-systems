# Civilopedia lookup

Add the core mod's lookup, which answers questions about game facts from the Civilopedia's own tables, the `GameInfo` tables, and localized text at runtime, so DLC and other mods are included. Part of [phase 1](README.md).

## Tasks

1. **Find the calls.** Read `<game>\Base\Assets\UI\Civilopedia\CivilopediaSupport.lua` to find how it builds sections and pages from the `CivilopediaSections`, `CivilopediaPages`, and `CivilopediaPageQueries` tables, and its chapters from `CivilopediaPageChapterParagraphs`.

   From the tuner, check that `DB.Query` and the `Search` calls work in `SentientSystemsCore_UI`, what `Search.Search` returns, and whether a search for `movement` finds the movement concept. Commit: `docs: record the Civilopedia calls`.
2. **Search.** Add `SentientSystems_Lookup(query)`, which returns up to 10 pages, each with its section, page ID, title, and a snippet. Build the index once per load from the Civilopedia's tables, as [findings/civilopedia.md](../../findings/civilopedia.md#sections-and-pages) describes, so the Concepts pages are included.

   Index each page's text as the `Search` description.

   Rank exact page IDs first, then titles that start with the query, titles that hold it, the game's `Search` results, and page IDs that hold it. Drop duplicates.

   A `Search` result's snippet is its excerpt, and another match's snippet is the first sentence of its text. If `Search` is missing, log a warning and use the substring matches. Commit: `feat(core): add Civilopedia search`.
3. **Page.** Add `SentientSystems_LookupPage(pageID, sectionID)`, which returns the page's title and its text as the game's page shows it. Run the game's own page layout with drawing calls that write lines, as [findings/civilopedia.md](../../findings/civilopedia.md#page-layouts) describes, and leave out the history chapters.

   When the layout is missing or fails, add the row's stats. `sectionID` is optional, and is needed only for a page ID that repeats across sections, such as `INTRO`. Commit: `feat(core): add Civilopedia pages`.
4. **Browse.** Add `SentientSystems_LookupSections()`, which lists each section's ID and title. Add `SentientSystems_LookupSection(sectionID)`, which lists the page ID and title of each page in one section. Commit: `feat(core): add Civilopedia browsing`.
5. **Bridge.** Add `lookup`, `lookupPage`, `lookupSections`, and `lookupSection` to `src/actions.ts`, with zod schemas and tests. Commit: `feat(core): call the lookup from the bridge`.

## Done when

In a running game, `lookup("settler")` finds the settler, `lookupPage("UNIT_SETTLER")` returns its cost and description without history text, and `lookup("movement")` finds the movement concept. A great person's page gives their ability.

A unit from Gathering Storm shows up in the same search. `lookupSection("CONCEPTS")` lists the Concepts pages.

## Record

- The Civilopedia calls and the state they run in, in [findings/civilopedia.md](../../findings/civilopedia.md).
- The lookup, its ranking, and its `## Decisions` rows, in [design/core/mod/civilopedia.md](../../design/core/mod/civilopedia.md).
