# State sections

`get_state` returns the whole state, so a model that only needs its units or cities again after an action reads every section. A section argument would let it read only what changed.

This debt blocks no phase or step. Pick it up when the smoke test shows that state reads cost too much.

## Now

- `get_state` in `packages/core/bridge/src/mcp/state-tools.ts` takes no arguments and returns all 21 sections that `STATE` in `src/state/state.ts` lists.
- The state was 247,075 bytes on turn 24 and 282,928 bytes on turn 403 of a game on a Huge map. `tiles` was 63% of it, while `units` was 1% to 2% and `cities` 4% to 5%. See the sizes in [testing.md](../design/testing.md#state-size).
- After an action, the tool returns "The game took the request." The model reads `get_state` again to see the result, such as a unit's new position.
- `get_choices` already takes an optional `cityID`, which cuts its largest part the same way.

## Proposal

Give `get_state` an optional `sections` argument, a list of section names such as `units` and `cities`. With it, the result holds only those sections. Without it, the result holds every section, as now.

The filter can run in the bridge, which still reads the whole state from the game but sends the model only the sections asked for. Or it can run in the core mod, as an optional argument to `SentientSystems_GetState`, which also skips building the other sections.

## Questions

- Does the filter run in the bridge or in the core mod? The bridge is simpler, and the core mod also saves the game's time to build the sections.
- Does a section list need its own zod schema, or does `STATE.partial()` read it?
- Which sections do the gate's turns re-read most after an action?

## Done when

`get_state` with `sections` returns only those sections, `get_state` without it returns the whole state, and a test covers both.
