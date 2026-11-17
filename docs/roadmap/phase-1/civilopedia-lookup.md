# Civilopedia lookup

Add the core mod's lookup, which answers questions about game facts from the Civilopedia's own tables, the `GameInfo` tables, and localized text at runtime, so DLC and other mods are included. Part of [phase 1](README.md).

## Tasks

1. **Find the calls.** Read `<game>\Base\Assets\UI\Civilopedia\CivilopediaSupport.lua` to find how it builds sections and pages from the `CivilopediaSections`, `CivilopediaPages`, and `CivilopediaPageQueries` tables, and its chapters from `CivilopediaPageChapterParagraphs`.

   From the tuner, check that `DB.Query` and the `Search` calls work in `SentientSystemsCore_UI`, what `Search.Search` returns, and whether a search for `movement` finds the movement concept. Commit: `docs: record the Civilopedia calls`.
2. **Search.** Add `SentientSystems_Lookup(query)`, which returns up to 10 pages, each with its section, page ID, title, and a snippet. Build the index once per load from the Civilopedia's tables, as [findings/civilopedia.md](../../findings/civilopedia.md#sections-and-pages) describes, so the Concepts pages are included.

   Index each page's text as the `Search` description.

   Rank exact page IDs first, then titles that start with the query, titles that hold it, the game's `Search` results, and page IDs that hold it. Drop duplicates.

   A `Search` result's snippet is its excerpt, and another match's snippet is the first sentence of its text. If `Search` is missing, log a warning and use the substring matches. Commit: `feat(core): add Civilopedia search`.
3. **Page.** Add `SentientSystems_LookupPage(pageID, sectionID)`, which returns the page's title, its `GameInfo` row, and its text. The text is the row's `Description`, or a Concepts page's `CONTENT` paragraphs. Leave out the `HISTORY`, `CAPSULE`, and `DETAILED` chapters.

   For the pages with no text, such as techs and leaders, read which other tables their page files show, as [findings/civilopedia.md](../../findings/civilopedia.md#titles-and-text) lists, and add the ones that hold rules.

   Leave out the row's `Hash`, `Index`, `RowId`, `rowid`, `PrimaryKey`, `Name`, and `Description` columns, and every column that is `0` or `false`. References to other rows stay as type names.

   `sectionID` is optional, and is needed only for a page ID that repeats across sections, such as `INTRO`. Commit: `feat(core): add Civilopedia pages`.
4. **Browse.** Add `SentientSystems_LookupSections()`, which lists each section's ID and title. Add `SentientSystems_LookupSection(sectionID)`, which lists the page ID and title of each page in one section. Commit: `feat(core): add Civilopedia browsing`.
5. **Bridge.** Add `lookup`, `lookupPage`, `lookupSections`, and `lookupSection` to `src/actions.ts`, with zod schemas and tests. Commit: `feat(core): call the lookup from the bridge`.

## Done when

In a running game, `lookup("settler")` finds the settler, `lookupPage("UNIT_SETTLER")` returns its cost and description without history text, and `lookup("movement")` finds the movement concept.

A unit from Gathering Storm shows up in the same search. `lookupSection("CONCEPTS")` lists the Concepts pages.

## Record

- The Civilopedia calls and the state they run in, in [findings/civilopedia.md](../../findings/civilopedia.md).
- The lookup, its ranking, and its `## Decisions` rows, in [design/core/mod/](../../design/core/mod/README.md#civilopedia-lookup). The rows cover pages from the Civilopedia's tables, the generic row dump over the game's page files, and dropping the history chapters.
