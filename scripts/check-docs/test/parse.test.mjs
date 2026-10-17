// Tests for parse.mjs.

import { describe, expect, test } from "vitest";
import { parse, resolveLink, slug } from "../src/parse.mjs";
import { lines } from "./helpers.mjs";

describe("parse", () => {
	test("slug follows GitHub's anchor rules", () => {
		expect(slug("Step 2: Turn on the tuner")).toBe("step-2-turn-on-the-tuner");
		expect(slug("Game properties (for checkpoint IDs)")).toBe("game-properties-for-checkpoint-ids");
		expect(slug("The `EnableTuner` setting")).toBe("the-enabletuner-setting");
		expect(slug("See [design](design.md)")).toBe("see-design");
	});

	test("repeated headings get numbered anchors", () => {
		const doc = parse("a.md", lines("# A", "## Notes", "## Notes"));

		expect([...doc.anchors]).toEqual(["a", "notes", "notes-1"]);
	});

	test("code blocks and inline code are blanked, and line numbers stay", () => {
		const doc = parse("a.md", lines("# A", "```", "## Not a heading", "```", "~~~", "text", "~~~", "Use `code` here."));

		expect(doc.headings.map((h) => h.text)).toEqual(["A"]);
		expect(doc.text[2]).toBe("");
		expect(doc.text[7]).toBe("Use        here.");
	});

	test("resolveLink handles relative, anchor-only, root, folder, and external links", () => {
		expect(resolveLink("docs/a/b.md", "../c.md#x")).toEqual({ path: "docs/c.md", anchor: "x" });
		expect(resolveLink("docs/a.md", "#x")).toEqual({ path: "docs/a.md", anchor: "x" });
		expect(resolveLink("docs/a.md", "/README.md")).toEqual({ path: "README.md", anchor: undefined });
		expect(resolveLink("docs/a.md", "design/")).toEqual({ path: "docs/design", anchor: undefined });
		expect(resolveLink("docs/a.md", "../")).toEqual({ path: "", anchor: undefined });
		expect(resolveLink("docs/a.md", "https://example.com")).toBe(null);
		expect(resolveLink("docs/a.md", "mailto:a@example.com")).toBe(null);
		expect(resolveLink("docs/a.md", "/")).toEqual({ path: "", anchor: undefined });
	});
});
