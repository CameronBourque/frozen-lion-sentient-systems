# Probe scripts

Four scripts in `packages/core/bridge/scripts/` come from phase 0, and their questions are answered. They add 757 lines that each change to the tuner client must keep working. See the [tech debt index](README.md).

## Now

| Script | Lines | Used by |
| --- | --- | --- |
| `gate.ts` | 313 | The `## Method` of [multiplayer.md](../findings/multiplayer.md). [Phase 1 step 9](../roadmap/phase-1/09-mcp-server.md) already deletes it |
| `probe.ts` | 188 | The `## Method` of [tuner-commands.md](../findings/tuner-commands.md) |
| `watch-states.ts` | 180 | The `## Method` of [state-list.md](../findings/state-list.md) |
| `hello.ts` | 76 | The hello check in [tuner-commands.md](../findings/tuner-commands.md), and the `--` example in [code.md](../rules/code.md) |

`npm run state` already checks the tuner client end to end, as `hello.ts` does. The [bridge README](../../packages/core/bridge/README.md) lists each script.

## Proposal

Delete `hello.ts`, `probe.ts`, and `watch-states.ts`. The findings that use `probe.ts` and `watch-states.ts` run them from commit `2291dc3`, the last commit on `main` before this debt, so each finding can still be re-tested.

## Questions

1. Will a finding need a re-test after a game patch? Answered: maybe, so each `## Method` runs the script from commit `2291dc3` instead of from `main`.

## Tasks

1. **Pin the methods.** In the `## Method` of [tuner-commands.md](../findings/tuner-commands.md) and of [state-list.md](../findings/state-list.md), run the script from a worktree at `2291dc3`. Add the commands `git worktree add tmp/probe-scripts 2291dc3` and `npm ci`, then run the script from `tmp/probe-scripts`. Commit: `docs: run the probe scripts from a pinned commit`.
2. **Hello.** Delete `scripts/hello.ts`, the `hello` npm script, and its row in the bridge README. In [code.md](../rules/code.md), change the `--` example to `npm run state -- 1`. Commit: `chore(core): remove the hello script`.
3. **Probe and watch-states.** Delete `scripts/probe.ts` and `scripts/watch-states.ts`, their npm scripts, and their rows in the bridge README. Commit: `chore(core): remove the probe and watch-states scripts`.

## Done when

- `packages/core/bridge/scripts/` holds only scripts that a current doc or task runs.
- Each finding's `## Method` still says how to re-test it.
