# Multiplayer

Status: open. Hotseat is confirmed on Windows. Online games are not tested.

What the tuner and the core mod can do in hotseat and online games. The advisors mod needs the tuner in online games. See [design/advisors.md](../design/advisors.md). Agent players need a way to act in any game that has you and an agent in it. See [design/agents/slot-type.md](../design/agents/slot-type.md).

## Questions

1. Does the game open the tuner socket during an online game?
2. Does read-only Lua run, such as listing cities and printing the turn number?
3. Does a read-only command cause a desync warning or other odd behavior?
4. Do event-driven prints, such as the turn signal, arrive in an online game?

## What we know now

### Hotseat

| Item | Value | Status |
| --- | --- | --- |
| Tuner | The game closes 4318 in hotseat, so no client can connect. Port 4319 is no substitute. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) | Confirmed, 2026-10-22 |
| Core mod | The mod runs, and `[SENTIENTSYSTEMS] AGENT_TURN` reaches `Lua.log`. A program can read the log, but it can't send anything into the game | Confirmed, 2026-10-22 |
| Turn order | The humans take their turns one at a time in slot order, each behind the pass screen, and then the AI players go. `AGENT_TURN` printed once for each human each round. See [lua-contexts.md](lua-contexts.md#turn-events-differ-by-script-type) | Confirmed, 2026-10-22 |
| Local player | `Game.GetLocalPlayer()` follows the human whose turn it is. See [game-api.md](game-api.md#active-player) | Confirmed, 2026-10-22 |
| Live reload | Editing the mod's UI Lua file reloads it in a running hotseat game. See [lua-contexts.md](lua-contexts.md#state-list-over-a-session) | Confirmed, 2026-10-22 |

### Several humans in single player

Single player keeps one human, so it can't stand in for hotseat with the tuner on. Each of these tries ended with one human, checked with `Players[id]:IsHuman()` in game:

- Setting a second slot to `SlotStatus.SS_TAKEN` on the single-player setup screen and clicking Start. The one human moved to the changed slot.
- Setting two slots to `SS_TAKEN`, reading both back as taken, and launching with `Network.HostGame(ServerType.SERVER_TYPE_NONE)` from the tuner. Firaxis's test code launches the same way, in `Base/Assets/UI/Automation/Automation_StandardTests.lua`, lines 121 to 157 and 309.
- Loading a hotseat save from the single-player load menu. `GameConfiguration.IsHotseat()` was `false`, and only slot 0 was human.

`GameConfiguration.GetHumanPlayerCount()` returned 1 in each try, even when `IsHuman()` was true for a different slot, so don't use it to count humans. Confirmed on Windows, 2026-10-22.

### Online

Untested. Hotseat closing 4318 suggests that online games close it too, but nobody has checked.

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

| Question | Result | Date |
| --- | --- | --- |
| Socket opens | | |
| Read-only Lua runs | | |
| No desync | | |
| Event prints arrive | | |

Date checked: hotseat on Windows on 2026-10-22. Online: not yet.
