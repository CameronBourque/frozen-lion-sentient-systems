// Tests for doc-paths.mjs: finding doc paths in text and checking them.

import { describe, expect, test } from "vitest";
import { checkDocPath, findDocPaths } from "../src/doc-paths.mjs";

const files = new Set(["docs/findings/game-api.md", "docs/design/core/bridge.md"]);
const exists = (p) => files.has(p);
const anchors = (p) => (p === "docs/findings/game-api.md" ? new Set(["what-we-know-now"]) : undefined);
const check = (text) => findDocPaths(text).map((ref) => checkDocPath(ref, { exists, anchors }));

describe("findDocPaths", () => {
	test("reads the path, anchor, and star", () => {
		expect(findDocPaths("See docs/findings/game-api.md#method and docs/new/a.md*.")).toEqual([
			{ raw: "docs/findings/game-api.md#method", path: "docs/findings/game-api.md", anchor: "method", planned: false },
			{ raw: "docs/new/a.md*", path: "docs/new/a.md", anchor: undefined, planned: true },
		]);
	});

	test.each([
		["a bare file name", "see game-api.md"],
		["another folder", "see packages/agents/sweat/balanced.md"],
		["a path inside a longer one", "see packages/x/docs/a.md and ../findings/a.md and ~/docs/a.md"],
		["a folder", "see docs/findings/"],
		["a file that isn't Markdown", "see docs/reference/a.json"],
	])("skips %s", (_, text) => {
		expect(findDocPaths(text)).toEqual([]);
	});

	test("ends the path before the sentence's period", () => {
		expect(findDocPaths("It is in docs/design/core/bridge.md.").map((ref) => ref.path)).toEqual(["docs/design/core/bridge.md"]);
	});
});

describe("checkDocPath", () => {
	test("accepts a path that exists", () => {
		expect(check("docs/design/core/bridge.md")).toEqual([undefined]);
	});

	test("accepts a path that exists under docs/", () => {
		expect(check("findings/game-api.md")).toEqual([undefined]);
		expect(check("findings/state.md")).toEqual(["findings/state.md does not exist"]);
	});

	test("reports a path that doesn't exist", () => {
		expect(check("docs/findings/tuner-protocol.md")).toEqual(["docs/findings/tuner-protocol.md does not exist"]);
	});

	test("checks an anchor when the headings are known", () => {
		expect(check("docs/findings/game-api.md#what-we-know-now")).toEqual([undefined]);
		expect(check("docs/findings/game-api.md#What-We-Know-Now")).toEqual([undefined]);
		expect(check("docs/findings/game-api.md#method")).toEqual(["#method is not a heading in docs/findings/game-api.md"]);
		expect(check("docs/design/core/bridge.md#anything")).toEqual([undefined]);
	});

	test("skips the anchor when the caller gives no headings", () => {
		const [ref] = findDocPaths("docs/findings/game-api.md#method");

		expect(checkDocPath(ref, { exists })).toBeUndefined();
	});

	test("accepts a planned path that doesn't exist yet", () => {
		expect(check("docs/reference/tools.md*")).toEqual([undefined]);
	});

	test("reports a planned path that exists", () => {
		expect(check("docs/design/core/bridge.md*")).toEqual(["docs/design/core/bridge.md* exists, so remove the *"]);
	});

	test("reports a planned path that isn't written from docs/", () => {
		expect(check("findings/agent-runs.md*")).toEqual(["findings/agent-runs.md* is planned, so write its path from docs/"]);
	});
});
