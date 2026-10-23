# Step 8: Civilopedia lookup

Add the core mod's lookup, which answers questions about game facts from the `GameInfo` tables and localized text at runtime, so DLC and other mods are included. Part of [phase 1](README.md).

## Tasks

1. **Find the calls.** Read `<game>\Base\Assets\UI\Civilopedia\` to find how the Civilopedia builds its sections and pages, including the Concepts section. Check from the tuner which calls work in `SentientSystemsCore_UI`. Commit: `docs: record the Civilopedia calls`.
2. **Search.** Add `SentientSystems_Lookup(query)`, which returns up to 10 matching pages, each with its section, type, and title. Match on type names, such as `UNIT_SETTLER`, and on localized titles. Commit: `feat(core): add Civilopedia search`.
3. **Page.** Add `SentientSystems_LookupPage(type)`, which returns the page's stats from `GameInfo` and its localized text. Commit: `feat(core): add Civilopedia pages`.
4. **Concepts.** Include the Concepts section's pages in the search, so a query such as `movement` finds the rules page. Commit: `feat(core): add Civilopedia concepts to the lookup`.
5. **Bridge.** Add `lookup` and `lookupPage` to `src/actions.ts`, with tests. Commit: `feat(core): call the lookup from the bridge`.

## Done when

In a running game, `lookup("settler")` finds the settler, `lookupPage("UNIT_SETTLER")` returns its cost and text, and `lookup("movement")` finds the movement concept. A unit from Gathering Storm shows up in the same search.

## Record

- The Civilopedia calls and the state they run in, in a new finding, `findings/civilopedia.md`. Add it to the [findings index](../../findings/README.md).
- The lookup, in [in-game-lua.md](../../design/core/in-game-lua.md).
