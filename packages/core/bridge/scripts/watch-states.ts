// Watches the game's Lua state list while you play, and prints each change with the time. It
// answers the state lifecycle questions in docs/findings/lua-contexts.md: whether the socket
// survives a load, whether the list or the indexes change, what a command to a gone index gets
// back, and whether ContextPtr:GetID() names the state. Run it with `npm run watch-states`, and
// stop it with Ctrl+C. An argument such as `npm run watch-states -- 4400` sets another port. In
// PowerShell, write the `--` as `'--'`, as docs/rules/code.md says.

import { log } from "../src/log.js";
import { type LuaState, parseStates } from "../src/tuner/client.js";
import { DEFAULT_PORT, TunerConnection } from "../src/tuner/connection.js";
import { type Frame, Tag } from "../src/tuner/framing.js";

const POLL_MS = 5_000;
const REPLY_TIMEOUT_MS = 5_000;
const SHOWN_CHARS = 120;
// States to ask for their ContextPtr ID. Main State is the tuner's own state, and has no ContextPtr.
const ID_CHECK_STATES = ["Main State", "InGame", "PlotInfo"];
const ID_CHECK = "print(ContextPtr and ContextPtr:GetID() or \"no ContextPtr\")";

const port = Number(process.argv[2] ?? DEFAULT_PORT);
const connection = new TunerConnection({ port });
// The list from the last poll. It's kept across reconnects, so a list after a load is compared
// with the list before it.
let previous: LuaState[] | undefined;
let handshaken = false;
// True after a failed attempt is logged, so retries while the game is closed print one line.
let refusalLogged = false;

function show(frame: Frame): string {
	const text = frame.strings.map((part) => JSON.stringify(part)).join("  ");

	return text.length <= SHOWN_CHARS ? `tag ${frame.tag}  ${text}` : `tag ${frame.tag}  ${text.slice(0, SHOWN_CHARS)}...`;
}

// Sends one frame and collects frames until one with `replyTag` arrives or the time runs out.
async function request(tag: number, text: string, replyTag = tag): Promise<Frame[]> {
	const frames: Frame[] = [];

	// Sent before the listener is added, so a send that throws leaves nothing behind. No reply can
	// arrive before the listener, because frames come in only after this code finishes.
	connection.send(tag, [text]);
	await new Promise<void>((resolve) => {
		const timer = setTimeout(finish, REPLY_TIMEOUT_MS);

		function finish(): void {
			clearTimeout(timer);
			connection.off("frame", onFrame);
			resolve();
		}

		function onFrame(frame: Frame): void {
			frames.push(frame);

			if (frame.tag === replyTag) {
				finish();
			}
		}

		connection.on("frame", onFrame);
	});

	return frames;
}

// Prints every frame a command gets back, or that it got none.
async function runAndShow(label: string, stateIndex: number, lua: string): Promise<void> {
	const frames = await request(Tag.Command, `CMD:${stateIndex}:${lua}`);

	log(`${label} in state ${stateIndex}:`);
	frames.forEach((frame) => console.log(`          ${show(frame)}`));

	if (!frames.some((frame) => frame.tag === Tag.Command)) {
		console.log(`          no tag 3 reply in ${REPLY_TIMEOUT_MS} ms`);
	}
}

async function checkIds(states: LuaState[]): Promise<void> {
	for (const name of ID_CHECK_STATES) {
		const state = states.find((candidate) => candidate.name === name);

		if (state) {
			await runAndShow(`ContextPtr ID of ${name}`, state.index, ID_CHECK);
		}
	}
}

// Lines such as "- 119 InGame" and "+ 120 InGame". Matching on both index and name shows a moved
// state as one removal and one addition.
function changes(before: LuaState[], after: LuaState[]): string[] {
	const key = ({ index, name }: LuaState) => `${index} ${name}`;
	const beforeKeys = new Set(before.map(key));
	const afterKeys = new Set(after.map(key));

	return [
		...before.filter((state) => !afterKeys.has(key(state))).map((state) => `- ${key(state)}`),
		...after.filter((state) => !beforeKeys.has(key(state))).map((state) => `+ ${key(state)}`),
	];
}

function inGameIndex(states: LuaState[]): string {
	return String(states.find(({ name }) => name === "InGame")?.index ?? "missing");
}

async function poll(): Promise<void> {
	if (!handshaken) {
		await request(Tag.App, "APP:");
		handshaken = true;
	}

	const reply = (await request(Tag.StateList, "LSQ:")).find((frame) => frame.tag === Tag.StateList);

	if (!reply) {
		log(`no state list reply in ${REPLY_TIMEOUT_MS} ms`);

		return;
	}

	const states = parseStates(reply.strings);

	if (!previous) {
		log(`${states.length} states. InGame is ${inGameIndex(states)}.`);
		await checkIds(states);
	} else {
		const changed = changes(previous, states);

		if (changed.length > 0) {
			log(`state list changed: ${states.length} states. InGame is ${inGameIndex(states)}.`);
			changed.forEach((line) => console.log(`          ${line}`));

			const oldInGame = previous.find(({ name }) => name === "InGame");

			if (oldInGame) {
				await runAndShow("A command to the old InGame index", oldInGame.index, "print(\"still here\")");
			}

			await checkIds(states);
		}
	}

	previous = states;
}

connection.on("connected", () => {
	refusalLogged = false;
	log("connected");
});
connection.on("disconnected", (error) => {
	handshaken = false;

	if (!error) {
		log("disconnected");
	} else if (!refusalLogged) {
		refusalLogged = true;
		log(`not connected: ${error.message}. Retrying until the game is running.`);
	}
});
process.on("SIGINT", () => {
	connection.close();
	process.exit(0);
});

log(`Watching the tuner on port ${port}, every ${POLL_MS / 1000} s. Press Ctrl+C to stop.`);
connection.connect();

while (true) {
	if (connection.connected) {
		try {
			await poll();
		} catch (error) {
			// The socket can drop between the connected check and a send.
			log(`poll failed: ${(error as Error).message}`);
		}
	}

	await new Promise((resolve) => setTimeout(resolve, POLL_MS));
}
