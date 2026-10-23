# Step 1: Link the core mod

Add a script that links the core mod into the game's `Mods` folder, in place of the manual steps in the [core mod README](../../../packages/core/mod/README.md#install-for-testing). Part of [phase 1](README.md).

## Tasks

1. **Script.** Write `scripts/link-mod.mjs` at the repo root, and add a `link-mod` script to the root `package.json`. The script finds the Documents folder from the registry value `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\Personal`, so a OneDrive Documents folder works. It creates the junction with `fs.symlinkSync(target, path, "junction")`. Test the path logic with a fake registry value. Commit: `chore(core): add the mod link script`.
2. **Existing link.** When the junction exists and points at this checkout, print that and exit 0. When it points somewhere else, or a real folder is there, print the path and exit 1 without touching it. Add `--remove`, which removes only a junction. Commit: `chore(core): handle an existing mod link`.
3. **README.** Replace the `mklink` steps in the core mod README with `npm run link-mod`. Keep the `rmdir` note for a manual removal. Commit: `docs: link the core mod with npm run link-mod`.

## Done when

On the test machine, `npm run link-mod` from a fresh clone links the mod, and the game lists **Sentient Systems Core** in **Additional Content**. A second run exits 0 and changes nothing.

## Record

- The registry value and the OneDrive case, in the [core mod README](../../../packages/core/mod/README.md#install-for-testing).
- The user mods folder in [local paths](../../findings/README.md#local-paths), if it differs.
