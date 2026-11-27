// Tests for model/menu.ts: the window that scrolls, the lines it draws, and
// the keys that answer it, through a fake terminal.

import { PassThrough } from "node:stream";
import { describe, expect, test, vi } from "vitest";
import { type Key, type Terminal, WINDOW_SIZE, askMenu, menuLines, moveMenu, processTerminal, screenRows, startMenu } from "../../src/model/menu.js";

const LONG = Array.from({ length: 25 }, (_, index) => `item ${index}`);

describe("startMenu", () => {
	test("starts at the top when the choice is in the first window", () => {
		expect(startMenu(25, 3)).toEqual({ selected: 3, top: 0 });
	});

	test("scrolls to show a choice further down", () => {
		expect(startMenu(25, 20)).toEqual({ selected: 20, top: 20 - WINDOW_SIZE + 1 });
	});

	test("keeps a choice out of range inside the list", () => {
		expect(startMenu(25, -1)).toEqual({ selected: 0, top: 0 });
		expect(startMenu(5, 9)).toEqual({ selected: 4, top: 0 });
	});
});

describe("moveMenu", () => {
	test("moves within the window without scrolling", () => {
		expect(moveMenu({ selected: 2, top: 0 }, 25, 1)).toEqual({ selected: 3, top: 0 });
	});

	test("scrolls down past the bottom row", () => {
		expect(moveMenu({ selected: WINDOW_SIZE - 1, top: 0 }, 25, 1)).toEqual({ selected: WINDOW_SIZE, top: 1 });
	});

	test("scrolls up past the top row", () => {
		expect(moveMenu({ selected: 5, top: 5 }, 25, -1)).toEqual({ selected: 4, top: 4 });
	});

	test("stops at either end", () => {
		expect(moveMenu({ selected: 0, top: 0 }, 25, -1)).toEqual({ selected: 0, top: 0 });
		expect(moveMenu({ selected: 3, top: 0 }, 25, Infinity)).toEqual({ selected: 24, top: 25 - WINDOW_SIZE });
	});
});

describe("menuLines", () => {
	test("draws a short list without markers", () => {
		expect(menuLines("Pick", ["a", "b"], { selected: 1, top: 0 })).toEqual(["Pick (arrow keys, then Enter)", "  a", "> b"]);
	});

	test("shows more below at the top of a long list", () => {
		const lines = menuLines("Pick", LONG, { selected: 0, top: 0 });

		expect(lines).toHaveLength(WINDOW_SIZE + 3);
		expect(lines[1]).toBe("");
		expect(lines[2]).toBe("> item 0");
		expect(lines.at(-1)).toBe("  ↓ more");
	});

	test("shows more above at the bottom of a long list", () => {
		const lines = menuLines("Pick", LONG, { selected: 24, top: 25 - WINDOW_SIZE });

		expect(lines[1]).toBe("  ↑ more");
		expect(lines.at(-2)).toBe("> item 24");
		expect(lines.at(-1)).toBe("");
	});
});

// A terminal whose input takes keypress events, and whose output and raw mode
// the test reads.
function fakeTerminal(columns?: number): Terminal & { output: string; raw: boolean[]; press: (key: Key) => void } {
	const input = Object.assign(new PassThrough(), {
		setRawMode: (raw: boolean) => {
			terminal.raw.push(raw);
		},
	});
	const terminal = {
		input,
		output: "",
		raw: [] as boolean[],
		write: (text: string) => {
			terminal.output += text;
		},
		press: (key: Key) => input.emit("keypress", undefined, key),
		columns: () => columns,
	};

	return terminal;
}

describe("askMenu", () => {
	test("returns the row chosen with the arrow keys and Enter", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", ["a", "b", "c"], 0, terminal);

		terminal.press({ name: "down" });
		terminal.press({ name: "down" });
		terminal.press({ name: "up" });
		terminal.press({ name: "return" });

		expect(await answer).toBe(1);
		expect(terminal.raw).toEqual([true, false]);
	});

	test("starts on the saved choice", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", LONG, 20, terminal);

		terminal.press({ name: "return" });

		expect(await answer).toBe(20);
	});

	test("jumps a window, and to either end", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", LONG, 0, terminal);

		terminal.press({ name: "end" });
		terminal.press({ name: "pageup" });
		terminal.press({ name: "home" });
		terminal.press({ name: "pagedown" });
		terminal.press({ name: "return" });

		expect(await answer).toBe(WINDOW_SIZE);
	});

	test("returns nothing on Ctrl+C", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", ["a"], 0, terminal);

		terminal.press({ name: "c", ctrl: true });

		expect(await answer).toBeUndefined();
		expect(terminal.raw).toEqual([true, false]);
	});

	test("returns nothing when the input closes", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", ["a"], 0, terminal);

		terminal.input.emit("end");

		expect(await answer).toBeUndefined();
		expect(terminal.raw).toEqual([true, false]);
	});

	test("ignores other keys and keypresses with no key", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", ["a", "b"], 0, terminal);

		terminal.press({ name: "x" });
		terminal.press({ name: "c" });
		terminal.input.emit("keypress", "?", undefined);
		terminal.press({ name: "return" });

		expect(await answer).toBe(0);
	});

	test("draws over the last drawing on each move", async () => {
		const terminal = fakeTerminal();
		const answer = askMenu("Pick", ["a", "b"], 0, terminal);

		terminal.press({ name: "down" });
		terminal.press({ name: "return" });
		await answer;

		expect(terminal.output).toBe("\x1b[0JPick (arrow keys, then Enter)\n> a\n  b\n\x1b[3A\x1b[0JPick (arrow keys, then Enter)\n  a\n> b\n");
	});

	test("moves up past the rows that a wide line wraps onto", async () => {
		// The heading is 29 characters and the first row 27, so each fills 2
		// rows of 20, and the second row fills 1.
		const terminal = fakeTerminal(20);
		const answer = askMenu("Pick", ["a, $8 in, $40 out per mil", "b"], 0, terminal);

		terminal.press({ name: "down" });
		terminal.press({ name: "return" });
		await answer;

		expect(terminal.output).toContain("\x1b[5A");
	});
});

describe("screenRows", () => {
	test("counts one row for each line that fits, and more for a line that wraps", () => {
		expect(screenRows(["abc", "", "abcd"], 4)).toBe(3);
		expect(screenRows(["abcde", "abcdefghi"], 4)).toBe(5);
	});

	test("counts characters, not the bytes or code units that hold them", () => {
		expect(screenRows(["  ↓ more"], 8)).toBe(1);
		expect(screenRows(["𝔸𝔹𝔺𝔻"], 4)).toBe(1);
	});

	test("counts one row for each line when the width is unknown", () => {
		expect(screenRows(["a".repeat(500), "b"], undefined)).toBe(2);
		expect(screenRows(["a".repeat(500)], 0)).toBe(1);
	});
});

describe("processTerminal", () => {
	test("writes to the process's output, and reads its width", () => {
		const write = vi.spyOn(process.stdout, "write").mockReturnValue(true);

		processTerminal().write("menu");

		expect(write).toHaveBeenCalledWith("menu");
		expect(processTerminal().columns()).toBe(process.stdout.columns);
		write.mockRestore();
	});
});
