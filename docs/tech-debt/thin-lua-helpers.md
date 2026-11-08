# Thin Lua helpers

Some Lua helpers only forward to another function, so a reader hops through names that add nothing.

## Now

Of the 40-odd helpers in `packages/core/mod/Scripts/` whose body is one `return`, most name a real idea, such as `IsAirUnit` or `CanAttack`. The forwarders do not.

`CannotProduce` in `Actions/SentientSystemsCore_ActionsCities.lua` is one call to `WithReasons`, which wraps `FailureReasons`. Three helpers build a reason message for four call sites.

The copies of the same helper in several files are in [duplicated-code.md](duplicated-code.md).

## Proposal

Inline a helper that only renames a call, or fold a chain of them into one. Keep a one-line helper that names an idea or gives a long expression a short name. Start with the city action helpers, since the code is new.

## Questions

1. What separates a helper that names an idea from one that only renames a call? A test, such as "more than one caller, or a name that explains a condition", would settle the rest.

## Done when

No helper in `packages/core/mod/Scripts/` only forwards to another with the same arguments. The Lua tests and coverage pass.
