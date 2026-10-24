# Core mod

The in-game half of core: turn events, the state serializer, the action API, checkpoint IDs, and Civilopedia lookup.

Design: [docs/design/core/in-game-lua.md](../../../docs/design/core/in-game-lua.md). Game API findings: [docs/findings/game-api.md](../../../docs/findings/game-api.md) and [docs/findings/lua-contexts.md](../../../docs/findings/lua-contexts.md).

## Tests

The Lua tests are in `Test/`. From the repo root, run `npm run test:lua`. They need Lua 5.1.5 and busted. See **Lint and test** in [code.md](../../../docs/rules/code.md#lint-and-test).

## Install for testing

A directory junction links this folder into the game's user mods folder, so the game loads your changes without a copy. Creating a junction doesn't need an administrator prompt. The mods folder for the test machine is in [local paths](../../../docs/findings/README.md#local-paths).

1. Close the game.
2. From the repo root, run `npm run link-mod`.
3. Start the game, open **Additional Content**, and turn on **Sentient Systems Core**.
4. Start or load a game with the mod on.

The script finds your Documents folder from the registry value `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\Personal`, so it works when OneDrive backs up your Documents folder. If it can't read the value, it warns and uses `%USERPROFILE%\Documents`. It makes the `Mods` folder if the game hasn't yet, but it needs the game to have started once.

Running it again is safe. If the link already points at this checkout, it says so and exits 0. If the link points at another folder, or a real folder is in its place, it prints the path, exits 1, and changes nothing.

After a change, load the game again. You don't need to restart the game or turn the mod on again. This held for changes to the Lua files and to the `.modinfo` on 2026-10-22.

To remove the link, run `npm run link-mod -- --remove`. In PowerShell, write the `--` as `'--'`. It removes only a link, never a real folder. To remove it by hand, run `rmdir` on the junction in the `Mods` folder. `rmdir` without `/S` removes only the link and leaves this folder alone.
