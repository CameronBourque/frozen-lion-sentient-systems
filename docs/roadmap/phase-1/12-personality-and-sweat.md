# Step 12: Personality and sweat level

Write one default personality and the balanced sweat level, and build the prompt from them. This step doesn't need the game. Part of [phase 1](README.md).

## Tasks

1. **Files.** Add `packages/agents/personalities/default.md` and `packages/agents/sweat/balanced.md`, laid out as [knowledge-files.md](../../design/knowledge-files.md#file-layout) shows. The sweat file follows the balanced row in [sweat-level.md](../../design/agents/sweat-level.md). Commit: `feat(agents): add the default personality and the balanced sweat level`.
2. **Bundle.** Add the knowledge files to the executable as SEA assets in `scripts/build-exe.mjs`, and read them with `sea.getAsset` in the executable and from disk in development. Commit: `feat(core): bundle the knowledge files into the executable`.
3. **Prompt.** Add `src/agents/prompt.ts`, which builds the system prompt from the rules of play, the personality, and the sweat level, and the turn message from the state and the blockers. The rules of play say to look up game facts with `lookup` and to give a `reason` on each action. Until the setup screen has the dropdowns, every agent gets the `random` personality, which picks from the personality files, and the `balanced` sweat level. Test the prompt with a fixed state. Commit: `feat(core): build the agent prompt`.
4. **Docs.** Describe where the agent code and the knowledge files live, in [knowledge-files.md](../../design/knowledge-files.md) and in the [agents README](../../../packages/agents/README.md). Commit: `docs: describe where the agent code lives`.

## Done when

The bridge executable builds a prompt from the bundled files with no `packages/agents` folder next to it, and the prompt holds the personality, the sweat level, and the state.

## Record

- Where the agent code and the knowledge files live, in [knowledge-files.md](../../design/knowledge-files.md), with a `## Decisions` row.
- How the executable carries the files, in [distribution.md](../../design/distribution.md).
