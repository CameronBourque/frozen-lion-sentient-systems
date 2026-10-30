# Fake game registry

`packages/core/mod/Test/FakeGame.lua` has two parts that each new fake game feature must update by hand: a header index of where each kind of data is documented, and a dependency check in `FakeGame.Register`. See the [tech debt index](README.md).

## Now

- The header comment has an `Example:` of `FakeGame.Install` in lines 4 to 21, and a "Where the data is documented" list in lines 23 to 35 that names each feature file. Each feature file already documents the data it reads.
- `FakeGame.Register(name, install, requires)` asserts that each feature in `requires` is registered first. The registration lines are a fixed list at the end of the same file.
- Some `requires` lists name features that aren't needed. With `Purchases` registered before `Production` and no `requires`, all 402 Lua tests passed on 2026-10-29.

## Proposal

Cut the header comment to its purpose lines, and drop the `requires` parameter. The registration order stays as it is.

## Questions

1. Does a wrong order fail with a clear error without the assert? Answered: yes. With `Purchases` registered first and no `requires`, 337 Lua tests failed on 2026-10-29 with `FakeGame/Purchases.lua:116: attempt to index field 'CityManager' (a nil value)`. The error names the feature's file and the global that an earlier feature adds.

## Tasks

1. **Header.** Delete the `Example:` and the "Where the data is documented" list from the header comment of `FakeGame.lua`, and keep its purpose lines. Commit: `test(core): cut the fake game header to its purpose`.
2. **Dependencies.** Drop the `requires` parameter of `FakeGame.Register`, its assert loop, its comment lines, and the lists on the registration lines. Keep the order of the registration lines. Commit: `test(core): drop the fake game dependency lists`.

## Done when

- A new fake game feature needs one registration line and nothing else in `FakeGame.lua`.
