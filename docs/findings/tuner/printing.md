# Tuner printing

Status: confirmed. The output size limit and how the game's log reads printed text are confirmed in a running game.

What a command can print through the tuner: the size limit on its output, and how the game's log reads the printed text. How commands run is in [tuner/commands.md](commands.md).

## Questions

None open.

## What we know now

- **Output size limit.** The limit is on a command's whole output, about 2 MiB, not on each print. From `SentientSystemsCore_UI`, one print of 2,097,022 characters arrived intact.

  With the state prefix, that line is 2,097,046 characters, 106 under 2 MiB. Two prints in one command, the first of 1,000,000 characters, arrived intact up to a second print of 1,096,980 characters, and failed at 1,096,990.

  Each print adds about 35 bytes of its own. A command over the limit sent no output frame and no tag 3 reply, and the connection answered no later command. The game logged no error. A new connection worked. Confirmed. Source: [Results](#results).
- **Printed text is a printf format.** The game's log, `Lua.log`, writes a print's text as a printf format, while the tuner sends it back unchanged. `print("a%%b")` came back as `a%%b` from the tuner and was logged as `a%b`.

  `print("50% done")` was logged as `50 1090428152one`, the `% d` taking a garbage integer, and `print("[%d]")` as `[1090428152]`. A `% s` or a `%n` makes the logger read a pointer that was never passed, and the game crashed with an access violation.

  A governor tree with a `% s` at character 10,663 crashed the game each time it was printed whole. The first 9,000 characters, each promotion alone, and each governor alone never crashed. Strings with 208 icon tokens and 193,106 bytes printed fine, so neither the icons nor the length are the cause.

  The mod's JSON encoder writes `%` as `\u0025`, so the printed text has no `%`, and the bridge's `JSON.parse` reads it back. An error line writes it as `\p`. Confirmed. Source: [Results](#results).

## Method

1. Turn on the tuner and start a game, as steps 1 and 2 of the [tuner protocol method](protocol.md#method) describe.
2. To find the size limit, send `print(string.rep("a", <n>))` to `SentientSystemsCore_UI` from the bridge, on a new connection for each size, and note which sizes get a reply.
3. To see how the log reads text, print text with a `%` in it, and compare `Lua.log` with what the tuner sent back.

## Results

- **Large prints from the core mod.** On 2026-10-23, the bridge sent `print(string.rep("a", <n>))` to `SentientSystemsCore_UI` in a single-player game, on a new connection for each size from 2,097,000 up.

  Each print up to the limit arrived as one line, in 29 to 73 ms from the send to the tag 3 reply:

  | Characters | Result | Time |
  | --- | --- | --- |
  | 1,000, 100,000, and 1,000,000, three times each | Arrived whole | 29 to 46 ms, after the first command on the connection, which took 379 ms |
  | 1,500,000 and 2,000,000 | Arrived whole | 41 and 73 ms |
  | 2,050,000, 2,090,000, 2,096,000, 2,097,000, 2,097,010, 2,097,020, and 2,097,022 | Arrived whole | 55 to 66 ms |
  | 2,097,023, 2,097,024, 2,097,026, 2,097,028, 2,097,030, 2,097,040, 2,097,050, 2,097,075, 2,097,090, 2,097,100, 2,097,200, 2,500,000, 3,000,000, and 4,000,000 | No reply in 10 to 60 s. A `print("pong")` sent next on the same connection got no reply either | None |

  On 2026-10-24, the bridge sent several prints in one command to `SentientSystemsCore_UI`, on a new connection for each command:

  | Prints in one command | Result | Time |
  | --- | --- | --- |
  | 2 of 1,000,000 characters | Arrived whole | 383 ms |
  | 1,000,000, then 1,096,900, 1,096,950, 1,096,960, 1,096,970, or 1,096,980 characters | Arrived whole | 150 to 369 ms |
  | 1,000,000, then 1,096,990 or 1,097,000 characters | No reply in 15 s | None |
  | 3 of 1,000,000 characters | No reply in 15 s | None |

  On 2026-10-24, the bridge read 2,500,001 bytes of JSON, a list of 500,000 `"é"` strings, through the core mod's stash, one piece per command. See **Stash** in [design/core/mod/json.md](../../design/core/mod/json.md#stash).

  `SentientSystems_Stash` encoded the list and printed `3` in 1,012 ms. Each `SentientSystems_PrintPiece` command took 29 to 36 ms, for pieces of 1,000,000, 1,000,000, and 500,001 bytes.

  The joined pieces parsed with `JSON.parse` into 500,000 `"é"` strings, with no U+FFFD replacement characters. A `SentientSystems_PrintPiece(1)` after the last piece raised `no stashed piece 1`.

- **Printed text and the log.** On 2026-10-27, in `SentientSystemsCore_UI`, the bridge printed a governor tree of 14,715 bytes, with 53 icon tokens and 11 percent signs, one of them a `% s`, through `SentientSystems_Stash` and `SentientSystems_PrintPiece`.

  The game crashed with an access violation each of three times. The core mod's game log ended at the `begin` marker of the `PrintPiece` command. A ladder of commands, each logged before it was sent, found the edge:

  | Command | Result |
  | --- | --- |
  | Build the tree twice, then wait 4 seconds | No crash |
  | Print each of its 42 promotions alone, then each of its 7 governors alone | No crash |
  | Print the first 6,000 and the first 9,000 characters | No crash. The first 9,000 hold one `% i` and no `% s` |
  | Print the first 12,000 characters | Crash. They hold the `% s` at 10,663 |
  | The same tree with each `%` written as `\u0025`, through `Stash` and `PrintPiece`, 14,773 bytes | Printed whole. The game kept answering. The bridge's reader parsed it, with the 11 percent signs back |

  The character after each `%` was checked by its code, without printing the text. The tree held `% i`, `% [`, `% y`, `%.`, `% s`, and `% o`, and the choices, which printed fine, held `% P`, `% U`, `% G`, `% I`, `% D`, `% [`, `%.`, `% f`, `% T`, `% C`, and `% r`.

  A conversion that only reads a number, such as `% i`, `% o`, or `% f`, logs a garbage number and doesn't crash, and `% s` reads a pointer. The tuner's own output is the raw text, so the bridge saw the right text throughout.

Date checked: 2026-10-23 and 2026-10-24 for the large prints from the core mod, and 2026-10-27 for printed text and the log.
