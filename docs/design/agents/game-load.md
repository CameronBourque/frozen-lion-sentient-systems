# Game load

How an agent's turn handles a game load: the cancel and the reset when the load ends, and the wait while the game doesn't answer before it. Part of the [turn loop](turn-loop/README.md).

## Cancel and reset

A `GAME_READY` line from the [load signal](../core/mod/lines.md#load-signal) cancels each running turn through its abort signal. The turn logs `turn_cancelled`, not `turn_stopped`, because the game it played is gone.

A signal that comes while a cancelled turn still waits on a call waits for it to finish, so the new turn never shares the agent with the old one.

The load also resets every agent. Its next turn plays even on a turn number it already ended, because the loaded save may be an earlier copy of that turn. It calls `startMemory` again, as on a restart, because the loaded game may be another game or an earlier save.

## Silent game

The game stops answering a while before a load's `GAME_READY`, such as while its load menu is open. Each tool call then waits out the tuner's 10 s timeout and fails, and before this wait, the model was called again for each failure.

In one live run, 7 model calls went to a game that didn't answer, before the cancel came.

After each failed tool call, `waitForGame` in `src/agents/game-wait.ts` sends the core mod an empty command. Any answer, even a Lua error, shows the game is there, and the turn goes on.

With no answer, the turn logs `game_silent`, checks again every 2 s, and logs `game_answers` when the game is back. The model sees the failed call as before.

The turn's abort signal ends the wait, so a load cancels a waiting turn as it cancels a running one. A missing core state counts as no answer, because a load is under way.

## Decisions

| Decision | Reason |
| --- | --- |
| A game load cancels the running turn, and resets the agents | The load resets the socket, which fails the Lua call in progress, but the model call would go on and act in the new game. The new game may be an earlier save of the same turn |
| The check asks the game, and doesn't read the failure text | The text is written for the model, so a check on its wording breaks when the wording changes. Only the game can say whether it answers |
| A failed tool call waits for the game before the next call or model call | A game that doesn't answer can only fail each call after a timeout, and each model call on those failures costs tokens. A check after each failed call is one fast Lua command when the game answers |
