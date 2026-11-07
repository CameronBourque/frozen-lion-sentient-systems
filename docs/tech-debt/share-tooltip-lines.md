# Share the tooltip line split

The income section keeps its own copy of the code that splits a game tooltip at `[NEWLINE]`. It should use the shared one in `SentientSystemsCore_Text.lua`.

## Now

`SentientSystems_GetTooltipLines` in `Scripts/SentientSystemsCore_Text.lua` splits a tooltip at `[NEWLINE]`, and drops the icons and the empty lines. The victories and tile sections use it.

`GetLines` in `Scripts/State/SentientSystemsCore_StatePlayerIncome.lua` does the split a second time. It keeps the icons and the empty lines, because `ReadSource` matches a whole line against a label.

## Proposal

Make `ReadSource` match a line without its icons, which is how the labels are written. Then replace `GetLines` with `SentientSystems_GetTooltipLines`, and run the income tests and a live check that the sources match the Yields tab of Reports.

Do it in a commit of its own, because it changes how a section reads its text.

## Questions

- Does an income label ever depend on an icon, or on an empty line? The tests and a live check against the Yields tab decide it.

## Done when

`GetLines` is gone from `SentientSystemsCore_StatePlayerIncome.lua`, the income tests pass, and a live read of the income section matches the Yields tab.
