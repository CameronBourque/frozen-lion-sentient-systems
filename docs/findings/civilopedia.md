# Civilopedia calls

Status: confirmed. Read from the game's files and tested from the tuner in `SentientSystemsCore_UI`, in a single-player Gathering Storm game on Windows.

How the game's Civilopedia builds its sections, pages, text, and search, and which of those calls the core mod's UI state can make. The lookup in [design/core/mod/](../design/core/mod/README.md#civilopedia-lookup) is built on them.

## Questions

None open.

## What we know now

### Sections and pages

`CivilopediaSupport.lua` in `<game>\Base\Assets\UI\Civilopedia\` builds the Civilopedia from `GameInfo` tables. Confirmed in files.

| Table | Holds |
| --- | --- |
| `CivilopediaSections` | Each section's ID and `Name` text key. The game has 18, such as `CONCEPTS` and `UNITS` |
| `CivilopediaPages` | Fixed pages, with section, page ID, layout, and `Name`. The game has 152, most of them in `CONCEPTS` |
| `CivilopediaPageQueries` | SQL that the Civilopedia runs with `DB.Query` to list pages from other tables, with the columns that hold the page ID and the name. The game has 27 |
| `CivilopediaSectionExcludes`, `CivilopediaPageExcludes` | Sections and pages to hide |
| `CivilopediaPageSearchTerms`, `CivilopediaPageSearchTermQueries` | Extra search words for some pages. The game has 19 rows and 1 query |
| `CivilopediaPageLayoutChapters` | The chapters of each layout |

- **Page IDs.** A query page's ID is its type name, such as `UNIT_SETTLER`, and `GameInfo.Types` has its kind, such as `KIND_UNIT`. A Concepts page has an ID such as `MOVEMENT_1`. Confirmed.
- **Each query reads one table.** The `FROM` table of each query names the `GameInfo` table that holds the page's row, such as `Units` or `Policies`. `BUILDINGS` and `WONDERS` both read `Buildings`. Confirmed.
- **Pages of a missing section are dropped.** The `LEADERS` query lists every leader, but `CivilopediaSections` has no `LEADERS` row, so `AddPage` drops those pages. After that, the only page ID in more than one section is `INTRO`, in 18 sections. Confirmed.
- **Count.** The game lists 1,854 pages after the excludes and before the missing-section drop. Gathering Storm pages such as `UNIT_SKIRMISHER` are among them. Confirmed.

### Titles and text

- **Titles.** A page's title is `Locale.Lookup` of its `Name`, unless a text key such as `LOC_PEDIA_<section>_PAGE_<page>_TITLE` exists. `FindPageTextKey` lists the keys it tries. Confirmed in files.
- **Chapter text.** A chapter's paragraphs come from `CivilopediaPageChapterParagraphs`, or from text keys such as `LOC_PEDIA_<section>_PAGE_<page>_CHAPTER_<chapter>_PARA_<n>`, numbered from 1 until one is missing. `GetChapterBody` lists the keys it tries. Confirmed.
- **Concepts.** A Concepts page uses the `Simple` layout, whose one chapter is `CONTENT`. `MOVEMENT_1` has its text in `LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_1_CHAPTER_CONTENT_PARA_1`. Confirmed.
- **Game objects.** Every other layout's only chapter is `HISTORY`, and the `Leader` layout adds `CAPSULE` and `DETAILED`.

  The rules text of a unit, building, or other object is the `Description` column of its row, such as `LOC_UNIT_SETTLER_DESCRIPTION`. The page files show its stats from the row and from other tables. Confirmed.
- **Pages with no rules text.** Of the 1,776 pages left after the missing-section drop, 486 have no `Description` column or chapter outside history, such as every tech, civic, leader, resource, terrain, government, and great person, and some buildings, such as `BUILDING_PALACE`.

  Their page files build the page from other tables, such as unlocks, yields, and traits. Confirmed.
- **Rows.** A `GameInfo` row also holds `Hash`, `Index`, `RowId`, `rowid`, and `PrimaryKey`, and many columns that are `0` or `false`. The settler's row has 57 columns, with `Cost=80` and `BaseMoves=2`. Confirmed.
- **Tags in text.** The text holds font icons such as `[ICON_Movement]`. `Locale.StripTags` removes them. Confirmed.

### Search

The Civilopedia's search is the game's `Search` API. `PopulateSearchData` indexes each page's title and its search terms. Confirmed in files.

- **Calls.** `Search.CreateContext(name, startTag, endTag, ellipsis)` returns `true`. `Search.AddData(name, key, title, description, terms)` adds one entry. `Search.Optimize(name)` runs after the last one.

  `Search.Search(name, query)` returns a list, or `nil` when nothing matches. `Search.DestroyContext(name)` removes it. A context with our own name works beside the Civilopedia's. Confirmed.
- **Results.** Each result is a list of 4 values: the key, the title with the match wrapped in the start and end tags, an excerpt of the description around the match with the same tags, and the plain title.

  Title matches come before description matches. No query returned more than 10 results. Confirmed.
- **Matching.** It matches word stems, so `amenities` finds "Amenity Sources", and `move` finds "Moving Great People". It matches the description text, so `flanking` finds `COMBAT_7`.

  It doesn't match misspellings, so `setler` finds nothing. It doesn't match type names, so `UNIT_SETTLER` finds nothing. Confirmed.
- **Speed.** Indexing all 1,854 pages, with each Concepts page's paragraphs or each object's `Description` as its description, took about 1 s of CPU time and 232,628 characters. `os.clock` counts whole seconds here. Confirmed.

### Calls in the core mod's UI state

`DB.Query`, every `Search` call above, `Locale.Lookup`, `Locale.HasTextKey`, `Locale.StripTags`, and the `GameInfo.Civilopedia*` tables all work in `SentientSystemsCore_UI`. Confirmed.

## Method

1. Read `CacheData_FetchData`, `CacheData_ProcessData`, `PopulateSearchData`, `GetChapterBody`, and `FindChapterTextKey` in `CivilopediaSupport.lua`, and the layout rows in `<game>\Base\Assets\Gameplay\Data\Civilopedia.xml`.
2. With a game loaded, send Lua to `SentientSystemsCore_UI` through the bridge's `TunerClient.run` that does each of these:
   - Print `type()` of `DB.Query`, `Search.CreateContext`, `Search.Search`, and the `Locale` calls.
   - List the sections, then count the fixed pages and the rows of each page query.
   - Print the settler's row with `pairs`, and look up its `Description`.
   - Check the `CONTENT` paragraph keys of `MOVEMENT_1`.
   - Count page IDs that repeat across sections.
3. Build a context named `SentientSystemsProbe` from every page, with its body text as the description. Search for `settler`, `setler`, `movement`, `move`, `amenities`, `flanking`, `zone of control`, and `UNIT_SETTLER`, and print each result's 4 values. Destroy the context.
4. Send `SentientSystemsCore_Civilopedia.lua` to `SentientSystemsCore_UI` without its `include` lines, and count the pages whose `text` is `nil`, by section and layout.

## Results

| Query | Results | First result |
| --- | --- | --- |
| `settler` | 10 | `UNITS\|UNIT_SETTLER` |
| `movement`, titles only | 2 | `CONCEPTS\|MOVEMENT_1`, "Movement Points" |
| `flanking` | 7 | `UNITPROMOTIONS\|PROMOTION_DOUBLE_ENVELOPMENT`, with `CONCEPTS\|COMBAT_7` sixth |
| `zone of control` | 7 | `CONCEPTS\|MOVEMENT_3` |
| `found city` | 1 | `CONCEPTS\|CITIES_2` |
| `skirmisher` | 2 | `UNITS\|UNIT_SKIRMISHER` |
| `setler` | 0 | None |
| `UNIT_SETTLER` | 0 | None |

Date checked: 2026-11-17
