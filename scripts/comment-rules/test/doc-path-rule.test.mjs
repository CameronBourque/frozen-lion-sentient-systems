// Tests for doc-path-rule.mjs: the messages for a comment's doc paths, and the
// docs that come from files on disk.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { findDocPathProblems, repoDocs } from "../src/doc-path-rule.mjs";

const files = new Set(["docs/findings/game-api.md"]);
const docs = { exists: (p) => files.has(p) };

describe("findDocPathProblems", () => {
	test("lets through a path that exists and a bare file name", () => {
		expect(findDocPathProblems("see docs/findings/game-api.md and game-api.md", docs)).toEqual([]);
	});

	test("reports a path that doesn't exist", () => {
		expect(findDocPathProblems("see docs/findings/old.md", docs)).toEqual(["docs/findings/old.md does not exist"]);
	});

	test("lets through a starred path to a doc that isn't written yet", () => {
		expect(findDocPathProblems("see docs/reference/tools.md*", docs)).toEqual([]);
	});

	test("reports a starred path to a doc that exists", () => {
		expect(findDocPathProblems("see docs/findings/game-api.md*", docs)).toEqual(["docs/findings/game-api.md* exists, so remove the *"]);
	});
});

describe("repoDocs", () => {
	let root;

	beforeAll(() => {
		root = fs.mkdtempSync(path.join(os.tmpdir(), "doc-paths-"));
		fs.mkdirSync(path.join(root, "docs"));
		fs.writeFileSync(path.join(root, "docs", "a.md"), "# A\n\n## Method\n");
	});

	afterAll(() => fs.rmSync(root, { recursive: true, force: true }));

	test("checks the files under the root", () => {
		const { exists } = repoDocs(root);

		expect(exists("docs/a.md")).toBe(true);
		expect(exists("docs/b.md")).toBe(false);
	});

	test("reads the anchors of a doc, and reads it once", () => {
		const { anchors } = repoDocs(root);

		expect(anchors("docs/a.md")).toEqual(new Set(["a", "method"]));

		fs.writeFileSync(path.join(root, "docs", "a.md"), "# Changed\n");

		expect(anchors("docs/a.md")).toEqual(new Set(["a", "method"]));
		expect(repoDocs(root).anchors("docs/a.md")).toEqual(new Set(["changed"]));
	});

	test("finds a stale anchor in a comment", () => {
		fs.writeFileSync(path.join(root, "docs", "a.md"), "# A\n\n## Method\n");

		expect(findDocPathProblems("see docs/a.md#results", repoDocs(root))).toEqual(["#results is not a heading in docs/a.md"]);
	});
});
