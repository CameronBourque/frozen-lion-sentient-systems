// Tests for game-load.ts, against the fake game.

import { once } from "node:events";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { readLine } from "../src/events.js";
import { onLoadEvent } from "../src/game-load.js";
import { Logger } from "../src/log.js";
import { TunerClient } from "../src/tuner/client.js";
import { Tag } from "../src/tuner/framing.js";
import { FakeGame } from "./tuner/fake-game.js";

describe("onLoadEvent", () => {
	let game: FakeGame;
	let client: TunerClient;
	let folder: string;
	let logger: Logger;
	let files: number;

	beforeEach(async () => {
		game = await FakeGame.start();
		game.states = [{ index: 0, name: "Main State" }, { index: 119, name: "InGame" }];
		client = new TunerClient({ port: game.port, retryDelayMs: 10, timeoutMs: 100 });
		folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
		logger = new Logger("debug", "");
		files = 0;
		vi.spyOn(console, "log").mockImplementation(() => {});
		client.connect();
		await once(client, "connected");
	});

	afterEach(async () => {
		vi.restoreAllMocks();
		logger.closeFile();
		client.close();
		await game.close();
		fs.rmSync(folder, { recursive: true, force: true });
	});

	// Reads a line the way main.ts does. Each new log file gets the next number.
	function read(line: string): void {
		readLine(line, logger, (event) => onLoadEvent(event, client, logger, () => path.join(folder, `${++files}.log`)));
	}

	// The event names in a log file, one for each line.
	function events(file: string): unknown[] {
		return fs.readFileSync(path.join(folder, file), "utf8").split("\n").filter((line) => line !== "").map((line) => (JSON.parse(line) as { event: string }).event);
	}

	function sent(tag: number): number {
		return game.received.filter((frame) => frame.tag === tag).length;
	}

	test("starts a new log file on LOAD_READY, with that line first", () => {
		logger.openFile(path.join(folder, "old.log"));
		read("SentientSystemsCore_UI: [SENTIENTSYSTEMS] CORE_LOADED SentientSystemsCore_UI");
		read("SentientSystemsCore_UI: [SENTIENTSYSTEMS] LOAD_READY");
		read("SentientSystemsCore_UI: [SENTIENTSYSTEMS] GAME_READY 1");

		expect(events("old.log")).toEqual(["core_loaded"]);
		expect(events("1.log")).toEqual(["load_ready", "game_ready"]);
	});

	test("starts a file for each load", () => {
		read("[SENTIENTSYSTEMS] LOAD_READY");
		read("[SENTIENTSYSTEMS] LOAD_READY");

		expect(events("1.log")).toEqual(["load_ready"]);
		expect(events("2.log")).toEqual(["load_ready"]);
	});

	test("lists the states again on the next command after GAME_READY", async () => {
		await client.run("InGame", "print(1)");

		// Like a load that moved InGame while the socket stayed up.
		game.states = [{ index: 0, name: "Main State" }, { index: 120, name: "InGame" }];
		read("[SENTIENTSYSTEMS] GAME_READY 1");
		await client.run("InGame", "print(1)");

		expect(game.commands.map(({ stateIndex }) => stateIndex)).toEqual([119, 120]);
		expect(sent(Tag.StateList)).toBe(2);
	});

	test("does nothing for other events", async () => {
		await client.run("InGame", "print(1)");
		read("[SENTIENTSYSTEMS] AGENT_TURN 0");
		await client.run("InGame", "print(1)");

		expect(files).toBe(0);
		expect(sent(Tag.StateList)).toBe(1);
	});
});
