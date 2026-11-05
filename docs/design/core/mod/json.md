# Core mod JSON

How the core mod encodes its replies as JSON, and how long JSON crosses the tuner in pieces. Part of the [core mod](README.md).

## JSON

`Scripts/SentientSystemsCore_Json.lua` has `SentientSystems_EncodeJson(value)`, which returns a value as JSON on one line. It encodes values by these rules:

- **Tables.** A table whose keys are 1 to n is a list, and an empty table is an empty list. Any other table is an object with sorted keys, and a number key, such as a unit ID, becomes text.
- **Numbers.** Whole numbers up to 2^53 keep every digit, other numbers keep 14 significant digits, and infinity and NaN become `null`.
- **Text.** The encoder escapes quotes, backslashes, and control characters, so text with newlines stays on one line. It writes each percent sign as `\u0025`.
- **Errors.** A function, a userdata, a boolean key, or a table that holds itself raises an error that names where, such as `value.cities[1].name`.

The game's log prints text as a printf format, where a `% s` crashed the game, so the printed text holds no `%`, and `JSON.parse` reads it back. See [findings/tuner/printing.md](../../../findings/tuner/printing.md#what-we-know-now).

## Stash

A command whose output is longer than about 2 MiB gets no reply, and the connection stops answering. The limit counts all of a command's prints together. See [findings/tuner/printing.md](../../../findings/tuner/printing.md#what-we-know-now).

So long text crosses in several commands. `SentientSystems_Stash(text)` keeps the text in pieces of at most 1,000,000 bytes, in place of any earlier stash, and prints how many there are.

The bridge then sends `SentientSystems_PrintPiece(<n>)` once for each piece and joins the pieces. After the last piece, the stash is cleared. The bridge decodes each print as UTF-8 on its own, so a piece never ends inside a UTF-8 character.

## Decisions

| Decision | Reason |
| --- | --- |
| The error helper and the JSON encoder escape the percent sign | The game's log prints text as a printf format, so a raw `%` prints garbage, and a `% s` crashed the game. `\u0025` is plain JSON, so the bridge needs nothing for it, and an error line's `\p` sits beside its other escapes |
| The JSON encoder sorts object keys | The same state gives the same text, so tests and logs can compare it |
| An empty table encodes as an empty list | Lua can't tell an empty list from an empty object. Lists, such as units or promotions, are often empty, and objects rarely are |
| Long JSON crosses in pieces of 1,000,000 bytes, one command each, from a stash | A command whose output passes about 2 MiB gets no reply and stops the connection, however many prints it makes. The stash encodes the state once. A 1 MB print arrives in about 40 ms |
