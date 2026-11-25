// Tests for model/sign-in/browser.ts: the command for each system, and a
// browser that fails to start changes nothing.

import type { ChildProcess } from "node:child_process";
import { EventEmitter } from "node:events";
import { expect, test } from "vitest";
import { type Spawn, browserCommand, openBrowser } from "../../../src/model/sign-in/browser.js";

const URL = "https://auth.openai.com/api/accounts/authorize?a=1&b=2";

test.each([
	["win32", ["rundll32", ["url.dll,FileProtocolHandler"]]],
	["darwin", ["open", []]],
	["linux", ["xdg-open", []]],
] as const)("opens the browser on %s", (platform, command) => {
	expect(browserCommand(platform)).toEqual(command);
});

test("starts the command detached with the URL, and ignores its failure", () => {
	const child = new EventEmitter() as EventEmitter & { unref: () => void; unrefed: boolean };
	const started: unknown[][] = [];

	child.unrefed = false;

	child.unref = () => {
		child.unrefed = true;
	};

	const run: Spawn = (...args) => {
		started.push(args);

		return child as unknown as ChildProcess;
	};

	openBrowser(URL, "win32", run);
	child.emit("error", new Error("ENOENT"));

	expect(started).toEqual([["rundll32", ["url.dll,FileProtocolHandler", URL], { detached: true, stdio: "ignore" }]]);
	expect(child.unrefed).toBe(true);
});
