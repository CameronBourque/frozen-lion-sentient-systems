# Personality and sweat level

Write the neutral personality and the balanced sweat level, and build the prompt from them. This step doesn't need the game. Part of [phase 2](README.md).

## Tasks

1. **Plan.** Update this step, the [phase 2 README](README.md), and [knowledge-files.md](../../design/knowledge-files.md) for knowledge files that live in the bridge. Commit: `docs: keep the knowledge files in the bridge`.
2. **Files.** Add `personalities/neutral.md` and `sweat/balanced.md` in `packages/core/bridge/knowledge/`, laid out as [knowledge-files.md](../../design/knowledge-files.md#file-layout) shows. The sweat file follows the balanced row in [sweat-level.md](../../design/agents/sweat-level.md). Commit: `feat(core): add the neutral personality and the balanced sweat level`.
3. **Bundle.** Add the knowledge files to the executable as SEA assets in `scripts/build-exe.mjs`, and read them with `sea.getAsset` in the executable and from disk in development. Commit: `feat(core): bundle the knowledge files into the executable`.
4. **Prompt.** Add `src/agents/prompt.ts`, which builds the system prompt from the rules of play, the personality, and the sweat level, and the turn message from the state and the blockers.

   Export only `systemPrompt`, which takes no state, and `turnMessage`. The system prompt holds only the parts that don't change between turns.

   Add the rules of play as `knowledge/rules/play.md`. They say to look up game facts with `search_civilopedia` and `read_civilopedia` and to give a `reason` on each action. A test checks that each tool the file names exists.

   Until the setup screen has the dropdowns, every agent gets the `neutral` personality and the `balanced` sweat level. An unknown name gets a warning and the same fallback. Test the prompt with a fixed state. Commit: `feat(core): build the agent prompt`.

## Done when

The bridge executable builds a prompt from the bundled files with no `knowledge` folder next to it, and the prompt holds the personality, the sweat level, and the state.

## Record

- How the executable carries the files, in [distribution.md](../../design/distribution.md).
