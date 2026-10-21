// Sends test commands to the running game's InGame state and prints every frame that comes back,
// with the time since the send. The output answers the open questions in
// docs/findings/tuner-commands.md: how the game wraps commands, how large output arrives, and
// whether replies keep their order. Run it with `npm run probe`, with a game loaded.

import { once } from "node:events";
import { TunerConnection } from "../src/tuner/connection.js";
import { type Frame, Tag } from "../src/tuner/framing.js";

// Each step sends its commands back to back, then waits for one tag 3 reply per command.
interface Step {
	name: string;
	commands: string[];
}

// The wrapper that client.ts may use. It's one expression, because the game puts the command
// inside a table constructor. The pcall keeps a runtime error from skipping the end marker.
function wrap(id: number, lua: string): string {
	return `(function() print("@@ss:begin:${id}") local ok, err = pcall(function() ${lua} end) `
		+ `print("@@ss:end:${id}:" .. (ok and "ok" or tostring(err))) end)()`;
}

const steps: Step[] = [
	// Question 2: what the tag 3 reply carries, and what runs inside _cmdr = {...}.
	{ name: "an expression's value", commands: ["1+1"] },
	{ name: "several values", commands: ["1+1, \"two\", true"] },
	{ name: "an assignment", commands: ["x = 5"] },
	// If x = 5 became a table field, x is nil here, and the last _cmdr holds x.
	{ name: "the assignment's result", commands: ["print(x, _cmdr and _cmdr.x)"] },
	{ name: "a statement", commands: ["local a = 1"] },
	{ name: "a function called on the spot", commands: ["(function() local a = 2 print(a) return a end)()"] },
	{ name: "the wrapper", commands: [wrap(1, "print(\"inside\")")] },
	{ name: "the wrapper with a runtime error", commands: [wrap(2, "error(\"boom\")")] },
	{ name: "the wrapper with a syntax error", commands: [wrap(3, "local end")] },
	// Question 3: how large output arrives, and whether any arrives after the tag 3 reply.
	{ name: "1,000 characters", commands: ["print(string.rep(\"a\", 1000))"] },
	{ name: "10,000 characters", commands: ["print(string.rep(\"a\", 10000))"] },
	{ name: "100,000 characters", commands: ["print(string.rep(\"a\", 100000))"] },
	{ name: "1,000,000 characters", commands: ["print(string.rep(\"a\", 1000000))"] },
	{ name: "2,000 prints", commands: ["(function() for i = 1, 2000 do print(i) end end)()"] },
	// Reply order: commands sent without waiting for each reply.
	{ name: "three commands at once", commands: ["print(\"first\")", "print(\"second\")", "print(\"third\")"] },
	{
		name: "a slow command, then a fast one",
		commands: ["(function() for i = 1, 5000000 do end print(\"slow\") end)()", "print(\"fast\")"],
	},
];

const STEP_TIMEOUT_MS = 30_000;
// How long to keep listening after a step's last reply, to catch output that arrives after it.
const LATE_LISTEN_MS = 500;
// Question 1: how long to listen for output that no command asked for.
const IDLE_LISTEN_MS = 60_000;
const SHOWN_CHARS = 80;
// A step with more frames than this shows only its first and last few.
const SHOWN_FRAMES = 20;
const SHOWN_ENDS = 5;

const connection = new TunerConnection();
const startedAt = Date.now();

// Shows a long string as its start and its length, such as a 1,000,000-character print.
function show(text: string): string {
	const escaped = JSON.stringify(text);

	return escaped.length <= SHOWN_CHARS ? escaped : `${escaped.slice(0, SHOWN_CHARS)}... (${text.length} chars)`;
}

// A frame and the time it arrived.
interface Received {
	frame: Frame;
	at: number;
}

function log(sentAt: number, received: Received[]): void {
	const line = ({ frame, at }: Received) => console.log(
		`  +${at - sentAt}ms  tag ${frame.tag}  ${frame.strings.map(show).join("  ")}`,
	);

	if (received.length <= SHOWN_FRAMES) {
		received.forEach(line);

		return;
	}

	received.slice(0, SHOWN_ENDS).forEach(line);
	console.log(`  ... ${received.length - 2 * SHOWN_ENDS} more frames`);
	received.slice(-SHOWN_ENDS).forEach(line);
}

// Collects frames until `done` returns true or the time runs out.
async function collect(done: (frames: Received[]) => boolean, timeoutMs: number): Promise<Received[]> {
	const frames: Received[] = [];

	await new Promise<void>((resolve) => {
		const timer = setTimeout(finish, timeoutMs);

		function finish(): void {
			clearTimeout(timer);
			connection.off("frame", onFrame);
			resolve();
		}

		function onFrame(frame: Frame): void {
			frames.push({ frame, at: Date.now() });

			if (done(frames)) {
				finish();
			}
		}

		connection.on("frame", onFrame);
	});

	return frames;
}

function replyCount(frames: Received[]): number {
	return frames.filter(({ frame }) => frame.tag === Tag.Command).length;
}

async function request(tag: number, text: string): Promise<Frame> {
	const isReply = ({ frame }: Received) => frame.tag === tag;
	const replies = collect((frames) => frames.some(isReply), STEP_TIMEOUT_MS);

	connection.send(tag, [text]);

	const reply = (await replies).find(isReply);

	if (!reply) {
		throw new Error(`No reply to ${text}`);
	}

	return reply.frame;
}

console.log("Waiting for the game's tuner on port 4318...");
connection.on("retrying", (delayMs) => console.log(`  not connected, retrying in ${delayMs} ms`));
connection.connect();
await once(connection, "connected");

console.log("APP: reply:", (await request(Tag.App, "APP:")).strings.map(show).join("  "));

const stateList = (await request(Tag.StateList, "LSQ:")).strings;
const inGameAt = stateList.findIndex((text, at) => at % 2 === 1 && text === "InGame");

if (inGameAt === -1) {
	throw new Error("No InGame state. Load a game, not the main menu");
}

const inGame = stateList[inGameAt - 1];

console.log(`States: ${stateList.length / 2}. InGame is ${inGame}.`);

for (const step of steps) {
	console.log(`\n${step.name}`);

	const sentAt = Date.now();
	const frames = collect((received) => replyCount(received) === step.commands.length, STEP_TIMEOUT_MS);

	for (const lua of step.commands) {
		console.log(`  send  ${show(lua)}`);
		connection.send(Tag.Command, [`CMD:${inGame}:${lua}`]);
	}

	const received = await frames;

	log(sentAt, received);

	if (replyCount(received) < step.commands.length) {
		console.log(`  timed out after ${STEP_TIMEOUT_MS} ms`);
	}

	const late = await collect(() => false, LATE_LISTEN_MS);

	if (late.length > 0) {
		console.log("  after the last reply:");
		log(sentAt, late);
	}
}

console.log(`\nListening for ${IDLE_LISTEN_MS / 1000} s. Select a city, open and close the full-screen map, and end a turn.`);

const listenedAt = Date.now();

log(listenedAt, await collect(() => false, IDLE_LISTEN_MS));
console.log(`\nDone in ${Math.round((Date.now() - startedAt) / 1000)} s.`);
connection.close();
