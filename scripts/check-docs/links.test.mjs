// Tests for links.mjs, check 1.

import { describe, expect, test } from "vitest";
import { checkLinks } from "./links.mjs";
import { buildRepo } from "./parse.mjs";
import { lines, messages } from "./test-helpers.mjs";

describe("links", () => {
	test("reports missing files and anchors only", () => {
		const repo = buildRepo({
			"docs/a.md": lines(
				"# A",
				"[ok](b.md) [missing](nope.md) [anchor](b.md#part-one) [bad anchor](b.md#nope)",
				"[folder](sub/) [folder anchor](sub/#sub) [web](https://example.com) [self](#a)",
				"`[in code](nope.md)`",
			),
			"docs/b.md": lines("# B", "## Part one"),
			"docs/sub/README.md": lines("# Sub"),
		});

		expect(messages(checkLinks(repo))).toEqual([
			"docs/a.md:2: link: nope.md does not exist",
			"docs/a.md:2: link: #nope is not a heading in docs/b.md",
		]);
	});

	test("reads reference links, and skips anchors into files that aren't Markdown", () => {
		const repo = buildRepo({
			"README.md": lines("# Root", "[image](docs/image.png#top)", "[ref]: docs/nope.md"),
			"docs/image.png": null,
		});

		expect(messages(checkLinks(repo))).toEqual(["README.md:3: link: docs/nope.md does not exist"]);
	});
});
