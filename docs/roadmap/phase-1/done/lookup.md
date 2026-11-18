# Phase 1: lookup

The finished step of [phase 1](../README.md) that gives agents game facts from the game's own Civilopedia. The index is in [README.md](README.md).

## Civilopedia lookup

Pull request: feat(core): add the Civilopedia lookup.

The core mod answers lookups from the Civilopedia's own tables at runtime, so DLC and other mods are included, and the bridge reads each one through the stash.

- **Search.** `lookup(query)` returns up to 10 pages, ranked by page ID, title, and the game's `Search`, each with a snippet.
- **Pages.** `lookupPage(pageID, sectionID)` returns a page as the game's Civilopedia shows it, without history, by running the game's own page layouts with drawing calls that write lines. Techs, leaders, and great people get their unlocks, agendas, and abilities this way.
- **Browsing.** `lookupSections()` lists the sections with page counts, and `lookupSection(sectionID)` lists one section's pages by group, in the game's order.
- **Risk.** A new row in [risks.md](../../../risks.md) says the Civilopedia's text is written for human players.

- How the lookup works and why, in [design/core/mod/civilopedia.md](../../../design/core/mod/civilopedia.md).
- The Civilopedia's tables, search, and page layouts, and the calls that work in the core mod's UI state, in [findings/civilopedia.md](../../../findings/civilopedia.md).
