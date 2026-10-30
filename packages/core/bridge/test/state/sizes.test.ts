// Tests for sizes.ts: the size of each section of the state.

import { describe, expect, test } from "vitest";
import { formatSectionSizes, sectionSizes } from "../../src/state/sizes.js";

describe("sectionSizes", () => {
	test("measures each section as JSON, largest first, with its share of the total", () => {
		const sizes = sectionSizes({ small: [1], large: { text: "abcdefgh" }, empty: [] }, 40);

		expect(sizes).toEqual([
			{ name: "large", bytes: 19, share: 19 / 40 },
			{ name: "small", bytes: 3, share: 3 / 40 },
			{ name: "empty", bytes: 2, share: 2 / 40 },
		]);
	});

	test("counts bytes, not characters", () => {
		expect(sectionSizes({ text: "é" }, 10)[0]?.bytes).toBe(4);
	});

	test("skips a section that is missing", () => {
		expect(sectionSizes({ gone: undefined, here: 1 }, 10).map((size) => size.name)).toEqual(["here"]);
	});
});

describe("formatSectionSizes", () => {
	test("lines up the names, the bytes with thousands separators, and the percents", () => {
		const lines = formatSectionSizes([
			{ name: "victories", bytes: 41200, share: 0.29 },
			{ name: "player", bytes: 900, share: 0.006 },
		]);

		expect(lines).toBe("  victories  41,200  29%\n  player        900  1%");
	});
});
