# Multiplayer

Status: confirmed. Hotseat and an online game are tested on Windows. Both close the tuner port, so no client can connect.

What the tuner and the core mod can do in hotseat and online games. The advisors mod needs the tuner in online games. See [design/advisors.md](../design/advisors.md). Agent players need a way to act in any game that has you and an agent in it. See [design/agents/slot-type.md](../design/agents/slot-type.md).

## Questions

None open.

## What we know now

### Hotseat

| Item | Value | Status |
| --- | --- | --- |
| Tuner | The game closes 4318 in hotseat, so no client can connect. Port 4319 is no substitute. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) | Confirmed, 2026-10-22 |
| Core mod | The mod runs, and `[SENTIENTSYSTEMS] AGENT_TURN` reaches `Lua.log`. A program can read the log, but it can't send anything into the game | Confirmed, 2026-10-22 |
| Turn order | The humans take their turns one at a time in slot order, each behind the pass screen, and then the AI players go. `AGENT_TURN` printed once for each human each round. See [lua-contexts.md](lua-contexts.md#turn-events-differ-by-script-type) | Confirmed, 2026-10-22 |
| Local player | `Game.GetLocalPlayer()` follows the human whose turn it is. See [game-api.md](game-api.md#active-player) | Confirmed, 2026-10-22 |
| Live reload | Editing the mod's UI Lua file reloads it in a running hotseat game. See [state-list.md](state-list.md#state-list-over-a-session) | Confirmed, 2026-10-22 |

### Several humans in single player

Single player keeps one human, so it can't stand in for hotseat with the tuner on. Each of these tries ended with one human, checked with `Players[id]:IsHuman()` in game:

- Setting a second slot to `SlotStatus.SS_TAKEN` on the single-player setup screen and clicking Start. The one human moved to the changed slot.
- Setting two slots to `SS_TAKEN`, reading both back as taken, and launching with `Network.HostGame(ServerType.SERVER_TYPE_NONE)` from the tuner. Firaxis's test code launches the same way, in `Base/Assets/UI/Automation/Automation_StandardTests.lua`, lines 121 to 157 and 309.
- Loading a hotseat save from the single-player load menu. `GameConfiguration.IsHotseat()` was `false`, and only slot 0 was human.

`GameConfiguration.GetHumanPlayerCount()` returned 1 in each try, even when `IsHuman()` was true for a different slot, so don't use it to count humans. Confirmed on Windows, 2026-10-22.

### Online

| Item | Value | Status |
| --- | --- | --- |
| Tuner | The game closes 4318 in an online game too, as in hotseat. With the host loaded into the map, `netstat` showed nothing on 4318, and the game listened on `127.0.0.1:4319` only. The bridge and `npm run gate -- --read-only` waited for the tuner and never connected. Port 4319 is no substitute. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) | Confirmed, 2026-10-23 |
| Core mod | The mod runs, and `[SENTIENTSYSTEMS] AGENT_TURN 0` reached `Lua.log` once on each of turns 1 to 3. A program can read the log, but it can't send anything into the game | Confirmed, 2026-10-23 |

## Rules for the test

- Run read-only Lua only. Do not request any action, because an action can cause a desync.
- Use a private lobby if the game lets you start one alone. Otherwise play with a friend who knows it's a test.

## Method

1. Set `EnableTuner 1` and host an online game.
2. From `packages/core/bridge/`, run `npm run gate -- --read-only`. It prints the turn, your cities, and your units, and stops before any move. If it can't connect, the socket is closed, and the other questions can't be answered.
3. Start the bridge with `npm run dev`. It logs the core version and the turn when it connects.
4. Play two or three turns. Watch the bridge for a `turn` line each turn, and the game for desync messages.

## Results

| Question | Result | Date |
| --- | --- | --- |
| Socket opens | No. Nothing listened on 4318, and the bridge and the gate never connected | 2026-10-23 |
| Read-only Lua runs | Not reachable, because the socket is closed | 2026-10-23 |
| No desync | Not reachable, because no command could be sent. The game showed no desync message by turn 3 | 2026-10-23 |
| Event prints arrive | Not over the tuner. The turn signal reached `Lua.log` on each turn | 2026-10-23 |

Date checked: hotseat on Windows on 2026-10-22. An online game hosted from Windows on 2026-10-23.
