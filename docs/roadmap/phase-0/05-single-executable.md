# Step 5: Pick the single-executable build

Choose the tool that builds the bridge into one executable, and wire it into the release build. Part of [phase 0](README.md).

## Tasks

1. Compare the [candidates](../../findings/build-tooling.md#candidates) by following the [build tooling method](../../findings/build-tooling.md#method).
2. Add a `"build:exe"` script that meets the `dist/` requirement in [build-tooling.md](../../findings/build-tooling.md).

## Done when

`npm run build:exe` produces one runnable `.exe` in `dist/`. The `bridge` release job then stops failing.

## Record

Results and the choice, in [build-tooling.md](../../findings/build-tooling.md#results).
