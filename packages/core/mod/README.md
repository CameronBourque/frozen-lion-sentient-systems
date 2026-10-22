# Core mod

The in-game half of core: turn events, the state serializer, the action API, checkpoint IDs, and Civilopedia lookup.

Design: [docs/design/core/in-game-lua.md](../../../docs/design/core/in-game-lua.md). Game API findings: [docs/findings/game-api.md](../../../docs/findings/game-api.md) and [docs/findings/lua-contexts.md](../../../docs/findings/lua-contexts.md).

## Install for testing

A directory junction links this folder into the game's user mods folder, so the game loads your changes without a copy. Creating a junction doesn't need an administrator prompt. The mods folder for the test machine is in [local paths](../../../docs/findings/README.md#local-paths).

1. Close the game.
2. In `cmd`, from the repo root, run:

	```bat
	mklink /J "%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods\SentientSystemsCore" "%CD%\packages\core\mod"
	```

	If OneDrive backs up your Documents folder, use `%USERPROFILE%\OneDrive\Documents` in the first path.
3. Start the game, open **Additional Content**, and turn on **Sentient Systems Core**.
4. Start or load a game with the mod on.

After a change, load the game again. You don't need to restart the game or turn the mod on again. This held for changes to the Lua files and to the `.modinfo` on 2026-10-22.

To remove the link, run `rmdir` on the junction in the `Mods` folder. `rmdir` without `/S` removes only the link and leaves this folder alone.
