# Advisors mod

The advisors mod gives a human player read-only LLM advisors in place of the stock advisor, one per victory condition. It is a separate project that starts after the core mod is stable.

It uses the same bridge, state serializer, Civilopedia lookup, and personality file format as the agent players. The difference is the tools. An advisor reads your state, filtered by your fog of war, and cannot act.

There is one advisor per victory condition, for example `science-advisor.md` and `culture-advisor.md`. Each is a personality file with its own focus and voice.

Advisors speak when you ask, or at key moments such as a new era or a war declaration. They do not speak every turn. Speaking less often keeps the cost down and keeps advisors from repeating minor advice.

Advisors can work in online multiplayer games. They only read your own client's state, so they cannot cause a desync. Agent players can't, because their actions could. [findings/multiplayer.md](../findings/multiplayer.md) tracks whether the tuner works in an online game.

Code: [packages/advisors/](../../packages/advisors/README.md).

## Decisions

| Decision | Reason |
| --- | --- |
| Advisors are a separate, later mod | Core must be stable first |
| Advisors can run in online multiplayer, agent players cannot | Read-only advisors cannot cause a desync |
