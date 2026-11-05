// Tests for doc-paths.mjs, check 6.

import { describe, expect, test } from "vitest";
import { checkDocPaths } from "../src/doc-paths.mjs";
import { buildRepo } from "../src/parse.mjs";
import { lines, messages } from "./helpers.mjs";

const target = lines("# Target", "## Method");

const run = (...rows) => messages(checkDocPaths(buildRepo({ "docs/findings/game-api.md": target, "docs/a.md": lines(...rows) })));

describe("doc paths", () => {
	test("accepts a path that exists, in backticks and in link text", () => {
		expect(run("# A", "See `docs/findings/game-api.md` and [docs/findings/game-api.md](findings/game-api.md).")).toEqual([]);
	});

	test("reports a path that doesn't exist, in backticks and in link text", () => {
		expect(run("# A", "See `docs/findings/old.md`.", "", "See [findings/old.md](findings/game-api.md).")).toEqual([
			"docs/a.md:2: doc-path: docs/findings/old.md does not exist",
			"docs/a.md:4: doc-path: findings/old.md does not exist",
		]);
	});

	test("reports a path once when it is link text in backticks", () => {
		expect(run("# A", "See [`docs/findings/old.md`](findings/game-api.md).")).toEqual([
			"docs/a.md:2: doc-path: docs/findings/old.md does not exist",
		]);
	});

	test("leaves a bare file name and a path outside the docs alone", () => {
		expect(run("# A", "See `game-api.md`, `packages/agents/sweat/balanced.md`, and [old.md](findings/game-api.md).")).toEqual([]);
	});

	test("leaves plain text and code blocks alone", () => {
		expect(run("# A", "docs/findings/old.md in a sentence.", "", "```", "docs/findings/old.md", "```")).toEqual([]);
	});

	test("checks an anchor against the target's headings", () => {
		expect(run("# A", "`docs/findings/game-api.md#method` and `docs/findings/game-api.md#results`.")).toEqual([
			"docs/a.md:2: doc-path: #results is not a heading in docs/findings/game-api.md",
		]);
	});

	test("accepts a starred path to a doc that isn't written yet", () => {
		expect(run("# A", "Add `docs/reference/tools.md*` later.")).toEqual([]);
	});

	test("reports a starred path to a doc that exists", () => {
		expect(run("# A", "Add `docs/findings/game-api.md*` later.")).toEqual([
			"docs/a.md:2: doc-path: docs/findings/game-api.md* exists, so remove the *",
		]);
	});
});
