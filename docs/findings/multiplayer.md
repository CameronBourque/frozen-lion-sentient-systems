# Online multiplayer

Status: open. Not tested.

The advisors mod needs the tuner in online games, because advisors should work there. Agent players do not need it, because they stay in single player and hotseat. See [design/advisors.md](../design/advisors.md).

## Questions

1. Does the game open the tuner socket during an online game?
2. Does read-only Lua run, such as listing cities and printing the turn number?
3. Does a read-only command cause a desync warning or other odd behavior?
4. Do event-driven prints, such as the turn signal, arrive in an online game?

## Rules for the test

- Run read-only Lua only. Do not request any action, because an action can cause a desync.
- Use a private lobby if the game lets you start one alone. Otherwise play with a friend who knows it's a test.

## Method

1. Set `EnableTuner 1` and host an online game.
2. Connect FireTuner, or the bridge once it works.
3. Run:

   ```lua
   print(Game.GetCurrentGameTurn())
   for i, c in Players[Game.GetLocalPlayer()]:GetCities():Members() do print(c:GetName()) end
   ```

   `Game.GetCurrentGameTurn` is confirmed in the game's UI Lua. `c:GetName()` is unconfirmed.
4. Play two or three turns and watch for desync messages.

## Results

Nothing yet.

| Question | Result | Date |
| --- | --- | --- |
| Socket opens | | |
| Read-only Lua runs | | |
| No desync | | |
| Event prints arrive | | |
