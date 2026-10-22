# Step 12: Close out phase 0

Close the phase in the docs and release core `0.1.0`. Part of [phase 0](README.md).

## Tasks

1. Close the phase as described in [rules/docs.md](../../rules/docs.md#roadmap).
2. In [risks.md](../../risks.md), mark the FireTuner risk as proven with a link to the findings. If the tuner proved too slow or unstable, start the fallback instead.
3. If a result changes the design, such as where the action API runs, update [design/core/](../../design/core/README.md) to match.
4. Merge the first `feat(core): ...` PR. It produces core `0.1.0` with a working `build:exe`.
5. Run the core `0.1.0` executable in Windows Sandbox, as step 5 of the [build tooling method](../../findings/build-tooling.md#method) describes. Record the result in [build-tooling.md](../../findings/build-tooling.md#results).

## Done when

All of these hold, and core `0.1.0` is released:

- The released executable, not `tsx`, passes these checks:
  - Ending a turn in the game makes the bridge log `turn 0` within about a second. This is step 8's check, and it passed with `tsx` on 2026-10-22.
  - Starting the bridge in the middle of your turn makes it log the core version and `turn 0`, without ending a turn. Restarting it in the same turn logs `turn 0` again. This is step 9's check, and it passed with `tsx` on 2026-10-22.
  - The "Done when" checks of step [10](10-gate.md).
- Each findings file has a confirmed result and a date.
- The executable runs in Windows Sandbox.

## Record

Nothing new. The steps above update the docs.
