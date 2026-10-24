# Step 10: Tool reference

Generate `docs/reference/tools.md` from the MCP tool schemas, and add the workflow that keeps it current. The design is under **Tool reference** in [toolchain.md](../../design/core/toolchain.md). Part of [phase 1](README.md).

## Tasks

1. **Script.** Add `packages/core/bridge/scripts/tool-reference.ts` and a `tool-reference` script. It lists the tools from the MCP server and writes one section per tool, with its description and a table of its fields. Test the output for one fake tool. Commit: `feat(core): generate the tool reference`.
2. **Reference folder.** Run the script, and commit `docs/reference/tools.md` with a `docs/reference/README.md` index. Add the folder to the [docs map](../../README.md) and to the "Where each kind of fact lives" table in [rules/docs.md](../../rules/docs.md#no-repetition). Commit: `docs: add the tool reference`.
3. **Check.** Make `check-docs` skip the pattern rules in `docs/reference/`, because tool descriptions follow the model's needs. Keep the link checks. Commit: `chore: skip the writing patterns in generated docs`.
4. **Workflow.** Add `.github/workflows/tool-reference.yml` with the two jobs that [toolchain.md](../../design/core/toolchain.md) describes. The first job runs the script and uploads the file. The second job commits the file to the PR branch with the release app token and never runs `npm`. Skip the second job for Dependabot PRs. Commit: `ci: update the tool reference on pull requests`.

## Done when

A PR that changes a tool description gets a commit from the release app that updates `docs/reference/tools.md`, and the required checks run again on that commit.

## Record

- The script's name and the workflow file, in [toolchain.md](../../design/core/toolchain.md).
- The `docs/reference/` exception, in [rules/docs.md](../../rules/docs.md#automated-check).
