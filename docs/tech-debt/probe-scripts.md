# Probe scripts

Four scripts in `packages/core/bridge/scripts/` come from phase 0, and their questions are answered. They add 757 lines that each change to the tuner client must keep working. See the [tech debt index](README.md).

## Now

| Script | Lines | Used by |
| --- | --- | --- |
| `gate.ts` | 313 | The `## Method` of [multiplayer.md](../findings/multiplayer.md). [Phase 1 step 9](../roadmap/phase-1/09-mcp-server.md) already deletes it |
| `probe.ts` | 188 | The `## Method` of [tuner-commands.md](../findings/tuner-commands.md) |
| `watch-states.ts` | 180 | The `## Method` of [state-list.md](../findings/state-list.md) |
| `hello.ts` | 76 | The hello check in [tuner-commands.md](../findings/tuner-commands.md), and the `--` example in [code.md](../rules/code.md) |

`npm run state` already checks the tuner client end to end, as `hello.ts` does.

## Proposal

1. Delete `hello.ts`, and move the `--` example in [code.md](../rules/code.md) to `npm run state -- 1`.
2. Delete `probe.ts` and `watch-states.ts`, and their npm scripts.
3. In each finding's `## Method`, link the script at the last commit that has it, so the finding can still be re-tested.
4. Leave `gate.ts` to phase 1 step 9.

## Questions

1. Will a finding need a re-test after a game patch? If so, keeping `probe.ts` and `watch-states.ts` may cost less than restoring them from git.

## Done when

- `packages/core/bridge/scripts/` holds only scripts that a current doc or task runs.
- Each finding's `## Method` still says how to re-test it.
