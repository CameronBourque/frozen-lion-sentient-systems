// The bridge's structured log. Each call builds a record with the time, the level, a fixed event
// name, a message, and any fields, such as { event: "turn", msg: "Player 0's turn started",
// playerId: 0 }. The console prints the local time and the message, such as "2:05:09 PM  Player
// 0's turn started". A log file gets each record as one JSON line. Paths in the home folder start
// with "~". docs/design/core/logs.md has the design.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// From quietest to noisiest. A logger writes the records at its level and every quieter level.
export const LOG_LEVELS = ["error", "warn", "info", "decisions", "debug"] as const;

export type LogLevel = typeof LOG_LEVELS[number];

export const DEFAULT_LOG_LEVEL: LogLevel = "decisions";

// Extra fields for a record, such as { playerId: 0 }. They can't replace the record's own fields.
export type LogFields = Record<string, unknown> & { time?: never; level?: never; event?: never; msg?: never };

export interface LogRecord {
	// UTC, in ISO 8601 form, such as "2026-10-23T23:19:11.042Z".
	time: string;
	level: LogLevel;
	// A fixed name for each kind of line, such as "turn", so a filter doesn't match message text.
	event: string;
	// Reads on its own, because the console prints only the time and this.
	msg: string;
	[field: string]: unknown;
}

// What the console puts after the time for each level.
const CONSOLE_LABELS: Record<LogLevel, string> = {
	error: "error: ",
	warn: "warning: ",
	info: "",
	decisions: "",
	debug: "",
};

export function makeRecord(time: Date, level: LogLevel, event: string, msg: string, fields: LogFields = {}): LogRecord {
	return { time: time.toISOString(), level, event, msg, ...fields };
}

// Characters a regex reads as special, so a folder name can be matched as it is.
const REGEX_SPECIAL = /[.*+?^${}()|[\]\\]/g;
// What ends a folder name in a path: a separator or the end of the text. Without it, the home
// folder "C:\Users\me" would also match the start of "C:\Users\me2".
const FOLDER_END = String.raw`(?=[\\/]|$)`;

// Replaces the home folder with "~" in the message and in each string field, so a shared log
// doesn't hold the user's name. Windows paths ignore case, so the match does too.
export function hideHome(record: LogRecord, home: string): LogRecord {
	if (home === "") {
		return record;
	}

	const pattern = new RegExp(`${home.replace(REGEX_SPECIAL, String.raw`\$&`)}${FOLDER_END}`, "gi");

	return Object.fromEntries(Object.entries(record).map(([key, value]) => [key, typeof value === "string" ? value.replace(pattern, "~") : value])) as LogRecord;
}

// Whether a logger at one level writes a record at another.
export function writesLevel(loggerLevel: LogLevel, recordLevel: LogLevel): boolean {
	return LOG_LEVELS.indexOf(recordLevel) <= LOG_LEVELS.indexOf(loggerLevel);
}

// The console line for a record, with the local 12-hour time in front, such as
// "2:05:09 PM  warning: STATE_READY is not a known kind".
export function formatConsole(record: LogRecord): string {
	return `${new Date(record.time).toLocaleTimeString("en-US")}  ${CONSOLE_LABELS[record.level]}${record.msg}`;
}

// The log file for a game that starts at a time, in a logs folder next to the config file, such as
// "logs/2026-10-23-181911.log". The name has the local time, with no colons, which Windows doesn't
// allow in file names.
export function logFilePath(configPath: string, time: Date): string {
	const pad = (value: number): string => String(value).padStart(2, "0");
	const date = `${time.getFullYear()}-${pad(time.getMonth() + 1)}-${pad(time.getDate())}`;
	const clock = `${pad(time.getHours())}${pad(time.getMinutes())}${pad(time.getSeconds())}`;

	return path.join(path.dirname(configPath), "logs", `${date}-${clock}.log`);
}

export class Logger {
	// Set it again once the config file loads.
	level: LogLevel;
	// The open log file. Undefined before openFile, and after a file can't be written.
	private file?: { path: string; fd: number };

	// The folder that hideHome replaces with "~".
	private readonly home: string;

	constructor(level: LogLevel = DEFAULT_LOG_LEVEL, home = os.homedir()) {
		this.level = level;
		this.home = home;
	}

	error(event: string, msg: string, fields?: LogFields): void {
		this.log("error", event, msg, fields);
	}

	warn(event: string, msg: string, fields?: LogFields): void {
		this.log("warn", event, msg, fields);
	}

	info(event: string, msg: string, fields?: LogFields): void {
		this.log("info", event, msg, fields);
	}

	// An agent's choice and its reason.
	decision(event: string, msg: string, fields?: LogFields): void {
		this.log("decisions", event, msg, fields);
	}

	// Prompts, responses, and other detail that can make a log large.
	debug(event: string, msg: string, fields?: LogFields): void {
		this.log("debug", event, msg, fields);
	}

	// Closes the open log file, if any, and writes the next records to this one, in a new folder if
	// needed. Appends to a file that exists. If the file can't be opened, warns and logs to the
	// console only.
	openFile(file: string): void {
		this.closeFile();

		try {
			fs.mkdirSync(path.dirname(file), { recursive: true });
			this.file = { path: file, fd: fs.openSync(file, "a") };
		} catch (error) {
			this.fileFailed(file, error);
		}
	}

	closeFile(): void {
		if (this.file) {
			fs.closeSync(this.file.fd);
			this.file = undefined;
		}
	}

	// Drops the file before it warns, so the warning goes to the console only.
	private fileFailed(file: string, error: unknown): void {
		// fs only throws Errors.
		const reason = (error as Error).message;

		this.file = undefined;
		this.warn("log_file_failed", `Can't write the log file ${file}, so the bridge logs to the console only: ${reason}`, { path: file, reason });
	}

	// Writes a record at a level chosen at run time, such as an event's level from describeEvent.
	log(level: LogLevel, event: string, msg: string, fields?: LogFields): void {
		if (!writesLevel(this.level, level)) {
			return;
		}

		const record = hideHome(makeRecord(new Date(), level, event, msg, fields), this.home);

		// A synchronous write, so the lines stay in order and none is lost when the bridge exits.
		if (this.file) {
			try {
				fs.writeSync(this.file.fd, `${JSON.stringify(record)}\n`);
			} catch (error) {
				const { path: file, fd } = this.file;

				fs.closeSync(fd);
				this.fileFailed(file, error);
			}
		}

		const line = formatConsole(record);

		// stderr for errors and warnings, so they show even when stdout goes elsewhere.
		if (level === "error") {
			console.error(line);
		} else if (level === "warn") {
			console.warn(line);
		} else {
			console.log(line);
		}
	}
}
