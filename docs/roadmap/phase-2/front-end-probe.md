# Front-end probe

Find how the game's front end sets up and starts a game, and whether the core mod can drive it, so the [preset launcher](preset-launcher.md) can be built on known calls. Part of [phase 2](README.md).

This step answers questions 1 and 2 in [lua/state-list.md](../../findings/lua/state-list.md#questions).

## Tasks

1. **Front-end calls.** Read `<game>\Base\Assets\UI\FrontEnd\` to find how the setup screen sets the map, players, seed, and options, and how **Start Game** starts the game.

   Check from the tuner which calls work in the `MainMenu` or `FrontEnd` state. Commit: `docs: record the front-end calls that start a game`.
2. **Front-end report.** Test whether the core mod can run Lua in the front end. If it can, print `FRONT_END <screen>` when the player moves between the main menu, the setup screen, and a game. This answers question 2. Commit: `feat(core): report the front-end screen`.
3. **Loading screen.** Test whether Lua can press the loading screen's button after `LOAD_READY` from the [load signal](../../design/core/mod/lines.md#load-signal). This answers question 2. If it can, add the call to the core mod. Commit: `feat(core): start the game from the loading screen`.

## Done when

Questions 1 and 2 in [lua/state-list.md](../../findings/lua/state-list.md#questions) are answered, and the front-end calls that set up and start a game are recorded.

## Record

- The front-end calls and the answers to questions 1 and 2, in [lua/state-list.md](../../findings/lua/state-list.md). Remove the answered questions.
