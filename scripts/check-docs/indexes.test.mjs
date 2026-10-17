// Tests for indexes.mjs, check 2.

import { describe, expect, test } from "vitest";
import { checkIndexes } from "./indexes.mjs";
import { buildRepo } from "./parse.mjs";
import { lines, messages } from "./test-helpers.mjs";

describe("indexes", () => {
	test("passes when every file and subfolder is linked", () => {
		const repo = buildRepo({
			"docs/README.md": lines("# Docs", "[a](a.md) [sub](sub/README.md)"),
			"docs/a.md": "# A\n",
			"docs/sub/README.md": lines("# Sub", "[b](b.md)"),
			"docs/sub/b.md": "# B\n",
		});

		expect(checkIndexes(repo)).toEqual([]);
	});

	test("reports a missing README and unlinked children", () => {
		const repo = buildRepo({
			"docs/README.md": "# Docs\n",
			"docs/a.md": "# A\n",
			"docs/sub/b.md": "# B\n",
			"packages/x/notes.md": "# Not under docs\n",
		});

		expect(messages(checkIndexes(repo))).toEqual([
			"docs/README.md:1: index: a.md is not linked from this index",
			"docs/README.md:1: index: sub/ is not linked from this index",
			"docs/sub:1: index: folder has no README.md",
		]);
	});
});
