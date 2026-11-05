# Findings in subfolders

Group the 26 files in `docs/findings/` into topic subfolders, so the folder index and a reader's search stay small as the game findings grow.

## Now

- `docs/findings/` holds 26 files in one folder, and its index has 26 rows.
- 19 of the files are about the game (18 `game-*.md` files and `tile-visibility.md`). The action API steps add more, starting with the `actions-*.md` files.
- Docs link to these files by path in many places: the design files, the roadmap steps, the risks, and other findings.

## Proposal

Make one subfolder for each topic, each with its own `README.md` index, and keep the top `findings/README.md` as an index of the subfolders:

| Folder | Files |
| --- | --- |
| `tuner/` | `tuner-protocol.md`, `tuner-commands.md`, `tuner-setup.md` |
| `lua/` | `lua-contexts.md`, `state-list.md` |
| `game/` | every `game-*.md` file and `tile-visibility.md` |
| `tools/` | `build-tooling.md`, `multiplayer.md` |

Drop the topic prefix from the names inside a folder, such as `game/choices.md`. Move the files with `git mv`, then fix every link and anchor with the docs check. Move the local paths table to the top index.

## Questions

1. Should `game/` be split again, for example into the state, the choices, and the action calls?
2. Does `multiplayer.md` belong in `tools/`, or is it a game finding?

## Done when

- Every findings file is in a subfolder, and each folder has an index.
- `npm run check-docs` passes, with no broken link.
- [rules/docs.md](../rules/docs.md) and [AGENTS.md](../../AGENTS.md) name no old path.
