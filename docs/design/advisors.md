# Advisors mod

The advisors mod gives a human player read-only LLM advisors in place of the stock advisor, one per victory condition. It is a separate project that starts after the core mod is stable.

It uses the same bridge, state serializer, Civilopedia lookup, and personality file format as the agent players. The difference is the tools. An advisor reads your state, filtered by your fog of war, and cannot act.

There is one advisor per victory condition, for example `science-advisor.md` and `culture-advisor.md`. Each is a personality file with its own focus and voice.

Advisors speak when you ask, or at key moments such as a new era or a war declaration. They do not speak every turn. Speaking less often keeps the cost down and keeps advisors from repeating minor advice.

Advisors only read your own client's state, so they can't cause a desync in an online game, while agent players' actions could. But the game closes the tuner port in online games, as it does in hotseat, so the bridge can't reach an online game. Advisors start in single player, where the tuner stays open. The core mod still runs online, and its prints reach `Lua.log`. See [findings/multiplayer.md](../findings/multiplayer.md#online).

## Open questions

- How do advisors read your state in an online game? Candidates: the core mod prints your state to `Lua.log` at key moments and the bridge reads the log, which needs no input; live reload of a UI Lua file for questions, with `Lua.log` for answers; or a hook DLL. Decide before the advisors mod starts.

Code: [packages/advisors/](../../packages/advisors/README.md).

## Decisions

| Decision | Reason |
| --- | --- |
| Advisors are a separate, later mod | Core must be stable first |
| Advisors start in single player | The game closes the tuner port in online games and hotseat |
| Advisors may run in online multiplayer once they can read state there, agent players cannot | Read-only advisors cannot cause a desync |
