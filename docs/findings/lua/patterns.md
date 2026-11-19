# Lua patterns

Status: confirmed. The character classes of Lua patterns in the core mod's UI state are confirmed in a running game on Windows.

How the game's Lua matches the character classes of a pattern, such as `%a` and `%s`, against the UTF-8 text that `Locale.Lookup` returns. The rest of the dialect is in [lua/dialect.md](dialect.md).

## Questions

## What we know now

The classes `%a`, `%c`, `%d`, `%l`, `%p`, `%s`, `%u`, `%w`, and their capital forms follow the C locale, and in the game's UI state they classify bytes by Windows code page 1252. `os` is `nil`, so a script can't change the locale. Confirmed on Windows on 2026-11-19.

Text from `Locale.Lookup` is UTF-8, so each character outside ASCII is two or more bytes from 0x80 to 0xFF. A class matches some of those bytes and not others, so a pattern can split a character:

| Class | Bytes from 0x80 to 0xFF that match | What it breaks |
| --- | --- | --- |
| `%c` | 81, 8D, 8F, 90, 9D, AD | An escape of control characters escapes the last byte of `ā` (C4 81), `í` (C3 AD), `ō` (C5 8D), and Cyrillic `с` (D1 81) |
| `%s` | A0 | A trim cuts the last byte of `à` (C3 A0) or Cyrillic `Р` (D0 A0) at the end of the text |
| `%a`, `%w` | 73 and 76 bytes, among them the lead bytes C0 to FF and a few others | A word ends partway through a character. `Dīn` (C4 AB) ends at AB |
| `%l`, `%u` | 39 and 34 bytes | A split at a lower and upper case pair can fall inside a character |
| `%p` | 48 bytes | A punctuation match takes part of a character |
| `%d` | B2, B3, B9 | A number match takes part of a character |
| `%x` | None | Nothing |

`string.upper` and `string.lower` change no byte from 0x80 to 0xFF.

A set with a range of bytes from 0x80, such as `[\128-\255]`, matches no byte at all. Ranges below 0x80 work, so a set that holds every byte from 0x80 has to be negated: `[^%z\1-\64\91-\96\123-\127]` matches the ASCII letters and each byte from 0x80. Confirmed on Windows on 2026-11-19.

The core mod's JSON encoder escaped each `%c` byte as `\u0081` and so on, which broke a character in every text the bridge read. The state showed the great artist Kamāl ud-Dīn Behzād with a replacement character for each `ā`.

The Lua tests run in the C locale, where no byte from 0x80 to 0xFF matches a class, so they can't show this.

## Method

1. In `SentientSystemsCore_UI`, for each class, list the bytes from 128 to 255 for which `string.char(b):find("%" .. class)` matches.
2. List the bytes that `upper` and `lower` change.
3. Print `Locale.Lookup` for a name with `ā`, and the same text through `SentientSystems_EncodeJson`.
4. Count the bytes from 128 to 255 that `[\128-\255]` matches, and split the name into words with the negated set.

## Results

- **`_VERSION` and `os.setlocale`.** `2013.2.0 r13768`, and `os` is `nil`. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The bytes each class matches.** As the table above lists. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **`upper` and `lower` on bytes 128 to 255.** No byte changed. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **`LOC_GREAT_PERSON_INDIVIDUAL_KAMAL_UD_DIN_BEHZAD_NAME`.** `Kamāl ud-Dīn Behzād` from `Locale.Lookup`, and `"Kam�\u0081l ud-Dīn Behz�\u0081d"` through the encoder with `%c`. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The same name with the shared sets.** `"Kamāl ud-Dīn Behzād"` through the encoder. `Kamāl`, `ud`, `Dīn`, and `Behzād` as words with the negated set, which matched 180 bytes: 52 letters and the 128 bytes from 0x80.

  `[\128-\255]` matched none. A tooltip line ending in `à` kept it. Run in `SentientSystemsCore_UI` on 2026-11-19.

Date checked: running game on Windows on 2026-11-19.
