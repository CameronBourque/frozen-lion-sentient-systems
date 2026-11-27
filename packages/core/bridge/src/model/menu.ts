// A terminal menu that the arrow keys and Enter answer, with a window that
// scrolls through a long list. docs/design/core/picker.md has the design.

import { on } from "node:events";
import { emitKeypressEvents } from "node:readline";

// Small enough for VS Code's default terminal panel, so the terminal itself
// never scrolls.
export const WINDOW_SIZE = 5;

export interface MenuState {
	selected: number;
	// The first row in the window.
	top: number;
}

// Moves the window just far enough to show the selected row.
function showSelected(selected: number, top: number): MenuState {
	if (selected < top) {
		return { selected, top: selected };
	}

	return { selected, top: Math.max(top, selected - WINDOW_SIZE + 1) };
}

export function startMenu(count: number, selected: number): MenuState {
	return showSelected(Math.min(Math.max(selected, 0), count - 1), 0);
}

export function moveMenu(state: MenuState, count: number, step: number): MenuState {
	return showSelected(Math.min(Math.max(state.selected + step, 0), count - 1), state.top);
}

// In a list that scrolls, a more marker leaves a blank line when there is no
// more, so the menu keeps its height.
export function menuLines(title: string, labels: string[], state: MenuState): string[] {
	const heading = `${title} (arrow keys, then Enter)`;
	const rows = labels.slice(state.top, state.top + WINDOW_SIZE)
		.map((label, row) => `${state.top + row === state.selected ? ">" : " "} ${label}`);

	if (labels.length <= WINDOW_SIZE) {
		return [heading, ...rows];
	}

	return [
		heading,
		state.top > 0 ? "  ↑ more" : "",
		...rows,
		state.top + WINDOW_SIZE < labels.length ? "  ↓ more" : "",
	];
}

export interface Key {
	name?: string;
	ctrl?: boolean;
}

// The parts of process.stdin and process.stdout the menu uses. columns is
// read at each drawing, since the user may resize the terminal, and is
// undefined when the output isn't a terminal.
export interface Terminal {
	input: NodeJS.ReadableStream & { setRawMode: (raw: boolean) => unknown };
	write: (text: string) => void;
	columns: () => number | undefined;
}

export function processTerminal(): Terminal {
	return {
		input: process.stdin,
		write: (text) => process.stdout.write(text),
		columns: () => process.stdout.columns,
	};
}

// Up and down a row, a window, or to either end.
const STEPS: Record<string, number> = {
	up: -1,
	down: 1,
	pageup: -WINDOW_SIZE,
	pagedown: WINDOW_SIZE,
	home: -Infinity,
	end: Infinity,
};

// What a key does: cancel, choose the selected row, move by a step, or
// nothing. Raw mode turns Ctrl+C into a key, so the menu handles it.
export function keyAction(key: Key | undefined): "cancel" | "choose" | number | undefined {
	const name = key?.name ?? "";

	if (key?.ctrl === true && name === "c") {
		return "cancel";
	}

	if (name === "return") {
		return "choose";
	}

	return Object.hasOwn(STEPS, name) ? STEPS[name] : undefined;
}

// The rows the lines fill on the screen. A line wider than the terminal wraps
// onto more rows, such as a model's name with its price in a narrow panel.
export function screenRows(lines: string[], columns: number | undefined): number {
	const width = columns !== undefined && columns > 0 ? columns : Infinity;

	return lines.reduce((rows, line) => rows + Math.max(1, Math.ceil([...line].length / width)), 0);
}

// Draws over the last drawing: up to its first row, then clear below.
// Returns the number of rows drawn, for the next drawing.
function drawMenu(terminal: Terminal, lines: string[], previous: number): number {
	terminal.write(`${previous > 0 ? `\x1b[${previous}A` : ""}\x1b[0J${lines.join("\n")}\n`);

	return screenRows(lines, terminal.columns());
}

// Returns the chosen row, or undefined when the user presses Ctrl+C or the
// input closes.
export async function askMenu(title: string, labels: string[], start: number, terminal: Terminal): Promise<number | undefined> {
	let state = startMenu(labels.length, start);
	let drawn = drawMenu(terminal, menuLines(title, labels, state), 0);
	// Listens before the first await, so no key is missed.
	const keys = on(terminal.input, "keypress", { close: ["end"] }) as AsyncIterableIterator<[unknown, Key | undefined]>;

	emitKeypressEvents(terminal.input);
	terminal.input.setRawMode(true);
	terminal.input.resume();

	try {
		for await (const [, key] of keys) {
			const action = keyAction(key);

			if (action === "cancel") {
				return undefined;
			}

			if (action === "choose") {
				return state.selected;
			}

			if (action !== undefined) {
				state = moveMenu(state, labels.length, action);
				drawn = drawMenu(terminal, menuLines(title, labels, state), drawn);
			}
		}

		return undefined;
	} finally {
		terminal.input.setRawMode(false);
		terminal.input.pause();
	}
}
