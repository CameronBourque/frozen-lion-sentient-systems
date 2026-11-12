# Core mod actions

How the core mod runs actions through the game's own request functions, and the reasons a failed action returns. Part of the [core mod](../README.md).

## Action API

Each action wraps the request function the game's own UI calls, and the game checks legality. A failed action returns its reason. The reason comes from the game's check where it gives one, and from the API's own messages for common cases.

The game's UI Lua files ship as plain text and show which call each screen makes. See the [action findings](../../../../findings/actions/move-unit.md).

| File | Covers |
| --- | --- |
| [units.md](units.md) | Moves, unit orders, stances, attacks, upgrades, formations, and air and transport |
| [unit-jobs.md](unit-jobs.md) | Builder jobs, adding production, great people, and religious units |
| [cities.md](cities.md) | Production, purchases, trade routes, spy missions, and escape routes |
| [research.md](research.md) | The tech and the civic in research, and their queues |
| [government.md](government.md) | The policies in a government's slots, the paid unlock, and a change of government |
| [religion.md](religion.md) | The pantheon, founding a religion with its beliefs, and adding a belief |
| [great-people.md](great-people.md) | Recruiting, passing, and patronizing a great person |
| [governors.md](governors.md) | Appointing, promoting, and assigning a governor |
| [envoys.md](envoys.md) | Sending envoys to a city-state |
| [great-works.md](great-works.md) | Moving a great work between slots, and choosing an artifact |
| [city-fate.md](city-fate.md) | Keeping, razing, liberating, or refusing a captured or rebelled city |
| [world-congress.md](world-congress.md) | Voting in a World Congress session, and making a proposal |

### Results

Every action returns the same JSON, `{ "ok": true }` or `{ "ok": false, "reason": "<text>" }`, with no `reason` when it worked. `SentientSystems_RunAction(name, action, ...)` in `Scripts/Actions/SentientSystemsCore_Actions.lua` builds it, and the UI script loads the file.

The action is a named local function that takes the arguments after it. It returns nothing when it worked and the reason as text when it failed.

The public function is one line that passes its arguments to `RunAction`, so a search for the global finds its parameters and its comment. A Lua error in it comes back as a failure with the error's first line, so the bridge always reads a reason.

The bridge reads the result through the stash. `sendAction` in [actions.ts](../../../../../packages/core/bridge/src/actions/actions.ts) turns a failure to reach the game, or a reply that isn't a result, into a failed result with that error as the reason. The shape is the schema in the same file.

## Decisions

| Decision | Reason |
| --- | --- |
| Every failed action returns a reason | The agent can decide again instead of repeating a mistake |
| Each action is a named local function, and its public function is a written-out one-line wrapper | A search for the global finds its definition, its parameters, and its comment. A helper that defines the global by name would hide all three |
| An action calls one named function per major step, and each step returns the reason or nil | A step can be read alone, and a later action can reuse it. A step that several action files call moves to `SentientSystemsCore_Actions.lua` |
| Actions have no line limit | Splitting by step keeps them short, and a fixed number would split some steps in the wrong place |
