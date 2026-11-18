# Civilopedia lookup

How the core mod answers questions about game facts from the game's own Civilopedia, so an agent reads what a player reads. Part of the [core mod](README.md). [findings/civilopedia.md](../../../findings/civilopedia.md) has the game calls it uses.

## Index

`SentientSystemsCore_Civilopedia.lua` builds the index on the first call after a load. It reads each section and page as `CivilopediaSupport.lua` does, from the Civilopedia's tables and `GameInfo`, with the same excludes,

and drops a page whose section is missing. DLC and other mods are included, and the Concepts section gives the general rules, such as movement, combat, and terrain.

Each page keeps its title, its `GameInfo` row, its search terms, its chapters, and its text.

Its chapters are those of its layout except `HISTORY`, `CAPSULE`, and `DETAILED`, each with its header and paragraph text keys. Its text is the row's `Description`, then the chapters' paragraphs, with the icons named by the text helpers. A page with neither has no text.

## Search

`SentientSystems_Lookup(query)` in `SentientSystemsCore_CivilopediaSearch.lua` returns up to 10 pages, each once, from these lists in order:

1. Exact page IDs, in any case.
2. Titles that start with the query.
3. Titles that hold the query.
4. The game's `Search` results, from a context named `SentientSystemsLookup` that holds each page's title, text, and search terms.
5. Page IDs that hold the query.

Each result has its section, page ID, title, and a snippet. A `Search` result's snippet is the game's excerpt around the match, and any other result's is the first sentence of its text, cut to 200 characters. Without `Search`, the lookup prints one `ERROR` line and uses the other lists.

## Pages

`SentientSystems_LookupPage(pageID, sectionID)` in `SentientSystemsCore_CivilopediaPage.lua` returns one page's section, page ID, title, and text. It finds the page ID in any case.

`sectionID` is needed only for a page ID that more than one section has, such as `INTRO`. A page that isn't found, or an ID in more than one section with no section given, returns an `error` that says what to do.

The text is what the game's page shows. On the first page after a load, the core mod loads the game's page layouts into its own state, as `CivilopediaScreen.lua` does.

It then replaces the drawing calls of `CivilopediaSupport.lua` with ones that write lines:

- A stat box's title is a `##` heading, its headers are `###` headings, and its labels are `-` lines.
- A header is a `##` heading, and a header with a body is a `###` heading over its body.
- Paragraphs and chapters are plain lines.
- Quotes, portraits, and images draw nothing.

The chapter calls read the index, so a layout gets only the chapters that aren't history. A heading with nothing under it is left out.

When a page's layout is missing or fails, the text keeps what the layout drew. The page's own text follows unless the layout drew it, because a layout that fails partway can stop before the unit's Description at its end. A `## Stats` heading with the row's columns comes last.

The stats leave out `Hash`, `Index`, `RowId`, `rowid`, `PrimaryKey`, `Name`, `Description`, and each column that is `0` or `false`. A failed layout prints an `ERROR` line.

## Browsing

`SentientSystemsCore_CivilopediaBrowse.lua` lists what the Civilopedia holds, for an agent that doesn't know a page's name. Both calls sort as `CacheData_SortData` does, so the order matches the game's screen.

- `SentientSystems_LookupSections()` returns each section's ID, title, and page count, by the section's sort index.
- `SentientSystems_LookupSection(sectionID)` returns one section's pages in their page groups, such as Combat or Movement in Concepts, each with its page IDs and titles. Pages with no group come first. A section that isn't found returns an `error` that lists the section IDs.

The index keeps each page's group, with the group's title and sort index, and leaves out the pages of a group that `CivilopediaPageGroupExcludes` hides.

## Bridge

`packages/core/bridge/src/lookup/lookup.ts` has `lookup`, `lookupPage`, `lookupSections`, and `lookupSection`, which read each call's JSON through the stash and check it with its zod schema.

A query or an ID goes into the Lua call as a string literal, with each quote, backslash, and control character escaped. A not-found reply becomes a failed read with the core mod's error, so it reaches the agent as a reason.

## Decisions

| Decision | Reason |
| --- | --- |
| Game facts come from the Civilopedia at runtime | It includes DLC and mods with no upkeep |
| The lookup lists pages from the Civilopedia's own tables, not from a list of `GameInfo` tables | Mods add their pages there, the page IDs match the game's Civilopedia, and the Concepts pages come with no extra code |
| The lookup leaves out the history chapters, quotes, portraits, and images | They hold history and flavor, not rules, and cost tokens |
| Titles rank before the game's `Search` results, and substring matches fill in after them | `Search` matches word stems and text, but no misspellings or type names, and ranked "+1 Movement" promotions above Naval Movement |
| The index is built on the first lookup after a load | A load builds a new UI state. The build takes about 1 s, which a load that no agent looks anything up in doesn't pay |
| A page is drawn by the game's own page layout, with drawing calls that write lines | A tech, a leader, or a great person has no `Description`, and its layout reads up to 25 other tables. The layouts include the expansions' and other mods' versions, so no copy goes stale |
| A page is text with headings, not JSON fields | It costs fewer tokens and reads as the page does |
| A section lists its pages by page group, in the game's order | The groups say what a page is about, such as Movement in Concepts, so an agent can scan a section's titles by topic |
| The row's stats appear only when the layout is missing or fails | The layouts already show the numbers a player reads, such as costs, strength, and movement |
