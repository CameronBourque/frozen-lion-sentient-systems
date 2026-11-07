# Split the phase 1 done file

The phase 1 `done.md` will pass the 12,000-character limit, so it needs to split by topic into a folder. Do it after the great works and map layers step.

## Now

[roadmap/phase-1/done.md](../roadmap/phase-1/done.md) is about 9,900 characters, with 11 sections for the 11 finished steps. Phase 1 has 30 steps, and each section is about 900 characters, so the 19 steps to come would add about 17,000 more.

The phase 1 [README](../roadmap/phase-1/README.md) links each of the 11 sections from its step table, with a `done.md#...` anchor. [rules/docs.md](../rules/docs.md#structure) has one more in an example.

## Proposal

Turn `done.md` into a `done/` folder with a `README.md` index, and one file for each kind of step. [rules/docs.md](../rules/docs.md#structure) says a file over the limit splits by topic.

- `setup.md`: the mod link, config file, logs and errors, and load signal steps.
- `state.md`: the State steps.
- `actions.md`: the Action API steps.
- `agent.md`: the lookup, MCP server, model client, personality, memory, agent loop, smoke test, MVP gate, and close out steps.

Each file keeps the form of a section today: the pull request, a sentence on what it delivered, and the files and sections that hold its results.

Point the step table's "Done. See" cells at the file that now holds each section, and the example in the rules at a file that exists. Leave the phase 0 file as it is, because it is small.

Do it in a commit of its own, after the great works and map layers step has its entry, so that the entry goes straight into `state.md`.

## Questions

- Do the four groups keep each file well under the limit once all 30 steps are in? If the Action API group gets close, split it into the unit actions and the others.

## Done when

`done.md` is gone, the `done/` folder has an index and one file for each group, every link and step table cell points at the right file, and `npm run check-docs` passes.
