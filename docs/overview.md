# Overview

2026-10-14 · @Cameron Bourque

What the project builds, why, and what comes first. For how each part works, see [design/](design/README.md).

## What we build

We build three Civilization VI mods and one external program that let LLM agents play Civ VI as full players. The agents play against you in hotseat games, against the native AI in single-player games, or against each other while you watch.

The native AI is predictable after a few games. Agents with personalities, memory, and the ability to talk to you make each game different. Civ VI stays the base because its mechanics are the point. Building a separate game is out of scope.

## Parts

The project has four parts:

- Core, which is the core mod and the external bridge program. Together they read game state, run actions, and store agent memory. See [design/core/](design/core/README.md).
- The agent players mod. It adds the **Agent** player type, the turn loop, spectator mode, the narrator panel, and messaging. See [design/agents/](design/agents/README.md).
- The advisors mod. It adds read-only advisors, one per victory condition. The advisors mod is a later project. See [design/advisors.md](design/advisors.md).
- Knowledge and personality files. They teach the agents the rules and give each agent a playstyle. See [design/knowledge-files.md](design/knowledge-files.md).

## First milestone and targets

The first milestone, the minimum viable product (MVP), is one agent that finishes a full single-player game against the native AI. Every later phase builds on that agent loop. See [roadmap/](roadmap/README.md).

The mods target the Steam Workshop, and nontechnical users must be able to set them up. Windows and the Gathering Storm ruleset come first.

## Decisions

| Decision | Reason |
| --- | --- |
| Build on Civ VI, not a custom game | Its mechanics are the reason for the project |
| Three mods: core, agent players, advisors | Each mod has one job. Features stay separate |
