# Step 12: Close out phase 0

Close the phase in the docs and release core `0.1.0`. Part of [phase 0](README.md).

## Tasks

1. Close the phase as described in [rules/docs.md](../../rules/docs.md#roadmap).
2. In [risks.md](../../risks.md), mark the FireTuner risk as proven with a link to the findings. If the tuner proved too slow or unstable, start the fallback instead.
3. If a result changes the design, such as where the action API runs, update [design/core/](../../design/core/README.md) to match.
4. Merge the first `feat(core): ...` PR. It produces core `0.1.0` with a working `build:exe`.

## Done when

All of these hold, and core `0.1.0` is released:

- The released executable, not `tsx`, passes the "Done when" checks of steps [8](08-receive-turn-signal.md), [9](09-resync-on-connect.md), and [10](10-gate.md).
- Each findings file has a confirmed result and a date.

## Record

Nothing new. The steps above update the docs.
