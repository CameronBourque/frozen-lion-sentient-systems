# Optional reason field

Every action tool requires a `reason`, which costs output tokens on each action. A setting could make the field optional to save tokens.

This debt blocks no phase or step. Pick it up when the token cost of `reason` matters.

## Now

- `registerAction` in `packages/core/bridge/src/mcp/action.ts` makes `reason` a required string of at most 200 characters on every action tool, through its `REASON` schema.
- The [narrator panel](../design/agents/narration-and-messaging.md) shows the `reason` for each action, and the decisions level of the [logs](../design/core/logs.md) records it.
- A reason is one sentence. At an estimated 20 to 40 output tokens for each action and 10 to 30 actions a turn, `reason` costs about 1,000 output tokens a turn.

## Proposal

Add a setting to the [config file](../design/core/settings.md) that makes `reason` optional. `registerAction` reads the setting, so the change is in one place. When `reason` is optional, the narrator panel and the decisions log show the action without a reason.

## Questions

- Is the setting one value for every agent, or one value for each slot?
- Does the narrator panel need text in place of a missing reason, such as the action's name?
- What does a game without reasons lose for [evaluation](../design/evaluation.md) and the decision records in [turn-loop/decision-records.md](../design/agents/turn-loop/decision-records.md)?
- How many tokens does `reason` cost a turn in a real game? The smoke test measures the cost per turn, which answers this.

## Done when

The config file can make `reason` optional, the action tools accept a call without it when it is optional, and a test covers both settings.
