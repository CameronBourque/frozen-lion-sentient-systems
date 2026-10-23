# Step 12: Close out phase 0

Close the phase in the docs, and check the released core `0.2.0` executable. Part of [phase 0](README.md).

## Tasks

1. Close the phase as described in [rules/docs.md](../../rules/docs.md#roadmap).
2. In [risks.md](../../risks.md), mark the FireTuner risk as proven with a link to the findings. If the tuner proved too slow or unstable, start the fallback instead.
3. If a result changes the design, such as where the action API runs, update [design/core/](../../design/core/README.md) to match.
4. Run the `core-v0.2.0` executable in Windows Sandbox, as step 5 of the [build tooling method](../../findings/build-tooling.md#method) describes. The Sandbox has no game, so the executable only has to start and wait for the tuner. Record the result in [build-tooling.md](../../findings/build-tooling.md#results).
5. Download the same executable on the game machine, and run the checks below with it. Record the results in [build-tooling.md](../../findings/build-tooling.md#results).

## Done when

All of these hold:

- The released `core-v0.2.0` executable, not `tsx`, passes these checks:
  - Ending a turn in the game makes the bridge log `turn 0` within about a second. This is step 8's check, and it passed with `tsx` on 2026-10-22.
  - Starting the bridge in the middle of your turn makes it log the core version and `turn 0`, without ending a turn. Restarting it in the same turn logs `turn 0` again. This is step 9's check, and it passed with `tsx` on 2026-10-22.
- The bridge prints your cities, and a unit visibly moves on the map. This is step 10's check, and it passed with `tsx` and `scripts/gate.ts` on 2026-10-23. The executable doesn't run it, because `build:exe` bundles only `src/main.ts`, and the action API comes in [phase 1](../phase-1/README.md).
- Each findings file has a confirmed result and a date.
- The executable starts in Windows Sandbox.

## Record

Nothing new. The steps above update the docs.
