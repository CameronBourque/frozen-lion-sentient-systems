# Fake game registry

`packages/core/mod/Test/FakeGame.lua` has two parts that each new fake game feature must update by hand: a header index of where each kind of data is documented, and a dependency check in `FakeGame.Register`. See the [tech debt index](README.md).

## Now

- The header comment has a "Where the data is documented" list, about 16 lines, that names each feature file. Each feature file already documents the data it reads.
- `FakeGame.Register(name, install, requires)` asserts that each feature in `requires` is registered first. The registration lines are a fixed list at the end of the same file, so a wrong order already fails the tests that use the feature.

## Proposal

1. Delete the "Where the data is documented" list.
2. Drop the `requires` parameter and its assert loop, and keep the registration order.

## Questions

1. Does a wrong order fail with a clear error without the assert? If a feature reads a missing call as `nil`, the error may point far from the cause, and the assert is worth keeping.

## Done when

- A new fake game feature needs one registration line and nothing else in `FakeGame.lua`.
