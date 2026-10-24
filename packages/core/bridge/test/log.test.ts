// Tests for log.ts.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, type MockInstance, test, vi } from "vitest";
import { formatConsole, logFilePath, Logger, type LogLevel, makeRecord, writesLevel } from "../src/log.js";

afterEach(() => {
	vi.restoreAllMocks();
	vi.useRealTimers();
});

describe("makeRecord", () => {
	test("puts the time in UTC, then the level, event, message, and fields", () => {
		const record = makeRecord(new Date(Date.UTC(2026, 9, 23, 23, 19, 11, 42)), "info", "turn", "Player 0's turn started", { playerId: 0 });

		expect(JSON.stringify(record)).toBe("{\"time\":\"2026-10-23T23:19:11.042Z\",\"level\":\"info\",\"event\":\"turn\",\"msg\":\"Player 0's turn started\",\"playerId\":0}");
	});

	test("has no extra fields when none are given", () => {
		expect(Object.keys(makeRecord(new Date(), "warn", "bad_line", "x"))).toEqual(["time", "level", "event", "msg"]);
	});
});

describe("writesLevel", () => {
	test.each<{ logger: LogLevel; record: LogLevel; writes: boolean }>([
		{ logger: "error", record: "error", writes: true },
		{ logger: "error", record: "warn", writes: false },
		{ logger: "warn", record: "error", writes: true },
		{ logger: "warn", record: "info", writes: false },
		{ logger: "info", record: "decisions", writes: false },
		{ logger: "decisions", record: "info", writes: true },
		{ logger: "decisions", record: "debug", writes: false },
		{ logger: "debug", record: "debug", writes: true },
	])("a $logger logger writes a $record record: $writes", ({ logger, record, writes }) => {
		expect(writesLevel(logger, record)).toBe(writes);
	});
});

describe("formatConsole", () => {
	// A local time, so the test passes in any time zone.
	const time = new Date(2026, 9, 22, 14, 5, 9);

	test("puts the 12-hour local time in front of the message", () => {
		expect(formatConsole(makeRecord(time, "info", "connected", "Connected to the game's tuner"))).toBe("2:05:09 PM  Connected to the game's tuner");
	});

	test("marks a morning time with AM", () => {
		expect(formatConsole(makeRecord(new Date(2026, 9, 22, 9, 0, 0), "decisions", "x", "y"))).toBe("9:00:00 AM  y");
	});

	test("labels a warning", () => {
		expect(formatConsole(makeRecord(time, "warn", "bad_line", "STATE_READY is not a known kind"))).toBe("2:05:09 PM  warning: STATE_READY is not a known kind");
	});

	test("labels an error", () => {
		expect(formatConsole(makeRecord(time, "error", "core_error", "boom"))).toBe("2:05:09 PM  error: boom");
	});

	test("leaves the fields out", () => {
		expect(formatConsole(makeRecord(time, "info", "turn", "Player 0's turn started", { playerId: 0 }))).toBe("2:05:09 PM  Player 0's turn started");
	});
});

describe("logFilePath", () => {
	const config = path.resolve("/games/bridge/sentient-systems.yaml");

	test("names the file by the local date and time, in a logs folder next to the config file", () => {
		expect(logFilePath(config, new Date(2026, 9, 23, 18, 19, 11))).toBe(path.resolve("/games/bridge/logs/2026-10-23-181911.log"));
	});

	test("pads each part to two digits", () => {
		expect(logFilePath(config, new Date(2026, 0, 2, 3, 4, 5))).toBe(path.resolve("/games/bridge/logs/2026-01-02-030405.log"));
	});
});

describe("Logger", () => {
	function spyAll() {
		return {
			error: vi.spyOn(console, "error").mockImplementation(() => {}),
			warn: vi.spyOn(console, "warn").mockImplementation(() => {}),
			log: vi.spyOn(console, "log").mockImplementation(() => {}),
		};
	}

	test("prints errors to stderr, warnings to stderr, and the rest to stdout", () => {
		const print = spyAll();
		const logger = new Logger("debug");

		vi.useFakeTimers({ now: new Date(2026, 9, 22, 14, 5, 9) });
		logger.error("core_error", "boom");
		logger.warn("bad_line", "bad");
		logger.info("connected", "connected");
		logger.decision("move", "moved");
		logger.debug("prompt", "prompt");

		expect(print.error.mock.calls).toEqual([["2:05:09 PM  error: boom"]]);
		expect(print.warn.mock.calls).toEqual([["2:05:09 PM  warning: bad"]]);
		expect(print.log.mock.calls).toEqual([["2:05:09 PM  connected"], ["2:05:09 PM  moved"], ["2:05:09 PM  prompt"]]);
	});

	test("starts at the decisions level", () => {
		const print = spyAll();
		const logger = new Logger();

		logger.decision("move", "moved");
		logger.debug("prompt", "prompt");

		expect(logger.level).toBe("decisions");
		expect(print.log).toHaveBeenCalledOnce();
	});

	test("at the warn level, prints only warnings and errors", () => {
		const print = spyAll();
		const logger = new Logger("warn");

		logger.error("core_error", "boom");
		logger.warn("bad_line", "bad");
		logger.info("connected", "connected");

		expect(print.error).toHaveBeenCalledOnce();
		expect(print.warn).toHaveBeenCalledOnce();
		expect(print.log).not.toHaveBeenCalled();
	});

	test("logs at a level given at run time", () => {
		const print = spyAll();
		const logger = new Logger("info");

		logger.log("error", "core_error", "boom");
		logger.log("debug", "prompt", "prompt");

		expect(print.error).toHaveBeenCalledWith(expect.stringMatching(/ {2}error: boom$/));
		expect(print.log).not.toHaveBeenCalled();
	});

	test("uses a level set after it was made", () => {
		const print = spyAll();
		const logger = new Logger();

		logger.level = "error";
		logger.info("connected", "connected");

		expect(print.log).not.toHaveBeenCalled();
	});
});

describe("Logger files", () => {
	let folder: string;
	let logger: Logger;
	let warned: MockInstance<typeof console.warn>;

	beforeEach(() => {
		folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
		logger = new Logger("debug");
		vi.spyOn(console, "log").mockImplementation(() => {});
		vi.spyOn(console, "error").mockImplementation(() => {});
		warned = vi.spyOn(console, "warn").mockImplementation(() => {});
	});

	afterEach(() => {
		logger.closeFile();
		fs.rmSync(folder, { recursive: true, force: true });
	});

	// The records in a log file, one for each line.
	function records(file: string): unknown[] {
		return fs.readFileSync(file, "utf8").split("\n").filter((line) => line !== "").map((line): unknown => JSON.parse(line));
	}

	test("writes each record as one JSON line", () => {
		const file = path.join(folder, "game.log");

		vi.useFakeTimers({ now: new Date(Date.UTC(2026, 9, 23, 23, 19, 11)) });
		logger.openFile(file);
		logger.info("turn", "Player 0's turn started", { playerId: 0 });
		logger.warn("bad_line", "bad");

		expect(records(file)).toEqual([
			{ time: "2026-10-23T23:19:11.000Z", level: "info", event: "turn", msg: "Player 0's turn started", playerId: 0 },
			{ time: "2026-10-23T23:19:11.000Z", level: "warn", event: "bad_line", msg: "bad" },
		]);
	});

	test("writes only the records the level writes to the console", () => {
		const file = path.join(folder, "game.log");

		logger.level = "warn";
		logger.openFile(file);
		logger.info("connected", "connected");
		logger.error("core_error", "boom");

		expect(records(file)).toMatchObject([{ level: "error" }]);
	});

	test("makes the file's folder", () => {
		const file = path.join(folder, "logs", "game.log");

		logger.openFile(file);
		logger.info("connected", "connected");

		expect(records(file)).toHaveLength(1);
	});

	test("adds to a file that exists", () => {
		const file = path.join(folder, "game.log");

		fs.writeFileSync(file, "{\"msg\":\"before\"}\n");
		logger.openFile(file);
		logger.info("connected", "connected");

		expect(records(file)).toMatchObject([{ msg: "before" }, { msg: "connected" }]);
	});

	test("writes to the new file after a second openFile", () => {
		const first = path.join(folder, "first.log");
		const second = path.join(folder, "second.log");

		logger.openFile(first);
		logger.info("connected", "one");
		logger.openFile(second);
		logger.info("connected", "two");

		expect(records(first)).toMatchObject([{ msg: "one" }]);
		expect(records(second)).toMatchObject([{ msg: "two" }]);
	});

	test("warns and keeps logging to the console when the file can't be opened", () => {
		// A file in place of the log file's folder, so making the folder fails.
		const file = path.join(folder, "logs", "game.log");

		fs.writeFileSync(path.join(folder, "logs"), "");
		logger.openFile(file);
		logger.info("connected", "connected");

		expect(warned).toHaveBeenCalledOnce();
		expect(String(warned.mock.calls[0][0])).toContain(`warning: Can't write the log file ${file}, so the bridge logs to the console only: `);
		expect(console.log).toHaveBeenCalledWith(expect.stringMatching(/ {2}connected$/));
	});

	test("warns once and stops writing the file when a write fails", () => {
		const file = path.join(folder, "game.log");

		logger.openFile(file);
		vi.spyOn(fs, "writeSync").mockImplementationOnce(() => {
			throw new Error("disk full");
		});
		logger.info("connected", "one");
		logger.info("connected", "two");

		expect(warned).toHaveBeenCalledOnce();
		expect(String(warned.mock.calls[0][0])).toMatch(/: disk full$/);
		expect(fs.readFileSync(file, "utf8")).toBe("");
		expect(console.log).toHaveBeenCalledTimes(2);
	});

	test("closes with no file open", () => {
		expect(() => logger.closeFile()).not.toThrow();
	});
});
