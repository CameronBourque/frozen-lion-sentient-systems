// Tests for log.ts.

import { afterEach, describe, expect, test, vi } from "vitest";
import { formatLine, log } from "../src/log.js";

afterEach(() => {
	vi.restoreAllMocks();
	vi.useRealTimers();
});

describe("formatLine", () => {
	test("puts the 24-hour time in front", () => {
		expect(formatLine(new Date(2026, 9, 22, 14, 5, 9), "connected")).toBe("14:05:09  connected");
	});

	test("pads the hour of a morning time", () => {
		expect(formatLine(new Date(2026, 9, 22, 9, 0, 0), "turn 0")).toBe("09:00:00  turn 0");
	});
});

describe("log", () => {
	test("prints the line with the current time", () => {
		const print = vi.spyOn(console, "log").mockImplementation(() => {});

		vi.useFakeTimers({ now: new Date(2026, 9, 22, 14, 5, 9) });
		log("connected");

		expect(print).toHaveBeenCalledWith("14:05:09  connected");
	});
});
