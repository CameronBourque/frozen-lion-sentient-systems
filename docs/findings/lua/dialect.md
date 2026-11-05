# Lua dialect

Status: confirmed. The Lua version, numbers, library functions, and errors in the core mod's UI state are confirmed in a running game on Windows, against Lua 5.1.5.

The Lua the game runs in the core mod's states, against Lua 5.1.5. Which states exist and what each one can call is in [lua/contexts.md](contexts.md).

## Questions

None open.

## What we know now

- **Lua version.** `_VERSION` in `SentientSystemsCore_UI` is `2013.2.0 r13768`, a Havok Script version. Confirmed.
- **Numbers.** Every number is a double, as in Lua 5.1. `tostring(3.0)` is `3`, `tostring(2 ^ 53)` is `9.007199254741e+15`, `tostring(1 / 0)` is `inf`, and `tostring(0 / 0)` is `-nan(ind)`. `string.format("%d", 3.5)` truncates to `3`. See [Lua 5.1 comparison](#lua-51-comparison). Confirmed.
- **Lua 5.1 match.** 30 of 35 checks of number formatting and library functions return the same values as Lua 5.1.5. The other five are the functions in the next row. Confirmed.
- **Missing functions.** `load`, `setfenv`, `io`, `string.gfind`, and `table.getn` are `nil`. Lua 5.1.5 has all five. `loadstring`, `unpack`, and `os` exist. None of the Lua 5.2 to 5.4 additions that were checked exist: `table.unpack`, `table.move`, `utf8`, `math.type`, and `bit32`. Confirmed.
- **`debug` library.** `type(debug)` in `SentientSystemsCore_UI` is `nil`. Confirmed.
- **`_G` and `getfenv`.** `type(_G)` and `type(getfenv)` are `nil` in `SentientSystemsCore_UI` and in `GameCore_Tuner`, so a script can't look up a global by its name. Lua 5.1.5 has both. Confirmed.
- **Errors in `pcall`.** An error from `error("text")` or a runtime error, caught by `pcall` in `SentientSystemsCore_UI`, has a message with the error, then `stack traceback:` and one line for each call.

  Errors that reach the tuner have the same form. See [tuner/commands.md](../tuner/commands.md#what-we-know-now). An error raised with a table, such as `error({})`, has no trace. Confirmed.
- **Paths in errors.** An error in a mod file names the file by its full path, such as `C:\Users\<name>\Documents\My Games\Sid Meier's Civilization VI\Mods\SentientSystemsCore\UI\SentientSystemsCore_UI.lua:38`. The path holds the user's name. Confirmed.

The items were checked on Windows on 2026-10-23, and the `_G` item on 2026-10-26.

## Method

1. To check the Lua version and errors, run these in `SentientSystemsCore_UI`:

   ```lua
   print(_VERSION, type(debug))
   SentientSystems_CatchErrors("Probe", function() error("test") end)()
   SentientSystems_CatchErrors("Probe", function() error({}) end)()
   ```

2. To compare the dialect with Lua 5.1, run the same checks in `SentientSystemsCore_UI` and in Lua 5.1.5. Wrap each check in `pcall`, and print the expression and its value on one line. Compare the two outputs line by line.

## Results

### Lua 5.1 comparison

Each check ran in `SentientSystemsCore_UI` and in Lua 5.1.5 on Windows on 2026-10-23. In the `%q` row, the output holds a backslash and then a real newline, shown here without the newline.

| Check | `SentientSystemsCore_UI` | Lua 5.1.5 |
| --- | --- | --- |
| `tostring(3.0)` | `3` | `3` |
| `tostring(7 / 2)` | `3.5` | `3.5` |
| `tostring(2 ^ 53)` | `9.007199254741e+15` | `9.007199254741e+15` |
| `tostring(2 ^ 63)` | `9.2233720368548e+18` | `9.2233720368548e+18` |
| `tostring(1 / 0)` | `inf` | `inf` |
| `tostring(-1 / 0)` | `-inf` | `-inf` |
| `tostring(0 / 0)` | `-nan(ind)` | `-nan(ind)` |
| `tostring(0.1)` | `0.1` | `0.1` |
| `tostring(1e15)` | `1e+15` | `1e+15` |
| `tostring(1e16)` | `1e+16` | `1e+16` |
| `tostring(-0.0)` | `-0` | `-0` |
| `tostring(math.floor(3.7))` | `3` | `3` |
| `string.format("%d", 3)` | `3` | `3` |
| `string.format("%d", 3.5)` | `3` | `3` |
| `string.format("%.14g", 0.1)` | `0.1` | `0.1` |
| `string.format("%.17g", 0.1)` | `0.10000000000000001` | `0.10000000000000001` |
| `string.format("%q", "a\nb")` | `"a\b"` | `"a\b"` |
| `string.format("%04x", 31)` | `001f` | `001f` |
| `#"\195\169"` | `2` | `2` |
| `0 == -0` | `true` | `true` |
| `type(math.type)` | `nil` | `nil` |
| `type(unpack)` | `function` | `function` |
| `type(table.unpack)` | `nil` | `nil` |
| `type(utf8)` | `nil` | `nil` |
| `type(table.move)` | `nil` | `nil` |
| `type(loadstring)` | `function` | `function` |
| `type(load)` | `nil` | `function` |
| `type(setfenv)` | `nil` | `function` |
| `type(bit)` | `nil` | `nil` |
| `type(bit32)` | `nil` | `nil` |
| `type(os)` | `table` | `table` |
| `type(io)` | `nil` | `table` |
| `type(string.gfind)` | `nil` | `function` |
| `type(table.getn)` | `nil` | `function` |
| `select("#", nil, nil)` | `2` | `2` |

Date checked: running game on Windows on 2026-10-23, and the `_G` item on 2026-10-26.
