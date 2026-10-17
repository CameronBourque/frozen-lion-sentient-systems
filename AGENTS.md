# Frozen Lion's Sentient Systems

LLM agents that play Civilization VI as full players, through a core mod and an external TypeScript bridge that talks to the game over FireTuner.

## Docs

Start at [docs/README.md](docs/README.md). It maps each folder to the questions it answers. Read the folder index, then open only the files you need. Don't load whole folders.

## Rules

Follow [docs/rules/](docs/rules/README.md): [docs](docs/rules/docs.md), [writing](docs/rules/writing.md), [code](docs/rules/code.md), and [commits](docs/rules/commits.md).

## Checks

Before you open a pull request, run `npm run lint`, `npm run coverage`, and `npm run check-docs` from the repo root. [code.md](docs/rules/code.md#lint-and-test) and [docs.md](docs/rules/docs.md#automated-check) describe them.

## Layout

[docs/overview.md](docs/overview.md#parts) lists the packages and what each one holds.
