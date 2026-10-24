// The tuner protocol on top of a connection: the handshake, the Lua state list, state lookup by
// name, and running Lua. Requests go out one at a time, through one queue. Each command runs inside
// the marker wrapper from wrapper.ts, so its output can be told apart from other prints.
// docs/findings/tuner-protocol.md has the messages, and docs/findings/tuner-commands.md has how
// the game runs commands.

import { EventEmitter } from "node:events";
import { type ConnectionOptions, TunerConnection } from "./connection.js";
import { type Frame, Tag } from "./framing.js";
import { type Ending, parseMarker, wrap } from "./wrapper.js";

export interface ClientOptions extends ConnectionOptions {
	// How long a request waits for its reply after it's sent.
	timeoutMs?: number;
}

export interface LuaState {
	index: number;
	name: string;
}

export interface RunResult {
	lines: string[];
}

// A command that the game ran and that failed, with the game's error and stack trace.
export class TunerLuaError extends Error {
	override name = "TunerLuaError";

	constructor(message: string, readonly lines: string[]) {
		super(message);
	}
}

export class TunerTimeoutError extends Error {
	override name = "TunerTimeoutError";
}

// No state has the name, such as a mod's state when the mod is off or no game is loaded.
export class TunerMissingStateError extends Error {
	override name = "TunerMissingStateError";
}

// The state's index changed again after the client listed the states once more.
export class TunerStateError extends Error {
	override name = "TunerStateError";
}

// "connected" fires once the game answers the handshake, not when the socket opens. "output" fires
// for each printed line that belongs to no command, such as an event handler's print. The line
// keeps its state prefix, such as "PlotInfo: ".
export interface ClientEvents {
	connected: [];
	disconnected: [];
	output: [line: string];
}

// What one try at a command gives back when the state list is stale.
const STALE = Symbol("stale");

// A request waiting for the next frame with its tag. A command also collects the output that
// arrives before its reply.
interface Pending {
	tag: number;
	// The marker ID of a command.
	id: number | undefined;
	// The state name and colon that the game puts before each printed line.
	prefix: string;
	lines: string[];
	ending: Ending | undefined;
	resolve: (reply: Reply) => void;
	reject: (error: Error) => void;
	timer: NodeJS.Timeout | undefined;
}

interface Reply {
	frame: Frame;
	lines: string[];
	ending: Ending | undefined;
}

interface RequestOptions {
	id?: number;
	prefix?: string;
	timed?: boolean;
}

export class TunerClient extends EventEmitter<ClientEvents> {
	private readonly connection: TunerConnection;
	private readonly timeoutMs: number;
	// Requests sent and not yet answered, in the order they were sent.
	private readonly pending: Pending[] = [];
	// Calls waiting for the handshake to finish.
	private readonly readyWaiters: (() => void)[] = [];
	private ready = false;
	// The state list from the first lookup on this connection.
	private states: LuaState[] | undefined;
	// The end of the queue. Each request starts after the one before it settles.
	private queue: Promise<unknown> = Promise.resolve();
	private lastId = 0;
	// The command between its begin and end markers. Its state's prints are its lines.
	private openCommand: Pending | undefined;

	constructor(options: ClientOptions = {}) {
		super();
		this.connection = new TunerConnection(options);
		this.timeoutMs = options.timeoutMs ?? 10_000;
		this.connection.on("connected", () => {
			// A failed handshake means the socket dropped, and the connection retries on its own.
			this.handshake().catch(() => {});
		});
		this.connection.on("frame", (frame) => this.receive(frame));
		this.connection.on("disconnected", () => this.drop());
	}

	connect(): void {
		this.connection.connect();
	}

	close(): void {
		this.connection.close();
	}

	// Waits for the handshake, if it hasn't finished.
	async listStates(): Promise<LuaState[]> {
		await this.whenReady();

		const reply = await this.enqueue(() => this.request(Tag.StateList, "LSQ:"));

		this.states = parseStates(reply.frame.strings);

		return this.states;
	}

	// Drops the state list, so the next lookup lists the states again. For a load that may have
	// changed the indexes while the connection stayed up.
	forgetStates(): void {
		this.states = undefined;
	}

	// Lists the states on the first lookup after each connect, because a new connection may come
	// after a load that changed the indexes.
	async findState(name: string): Promise<LuaState> {
		const states = this.states ?? await this.listStates();
		const matches = states.filter((state) => state.name === name);

		if (matches.length === 0) {
			throw new TunerMissingStateError(`No Lua state is named ${name}`);
		}

		// SaveGameMenu is listed twice, and picking one could run Lua in the wrong state.
		if (matches.length > 1) {
			throw new Error(`${matches.length} Lua states are named ${name}`);
		}

		return matches[0];
	}

	// Runs Lua in the named state and resolves with the lines it printed in that state. A stale
	// state list gets one more try, with a fresh list.
	async run(stateName: string, lua: string): Promise<RunResult> {
		for (let attempt = 0; attempt < 2; attempt++) {
			const result = await this.runOnce(stateName, lua);

			if (result !== STALE) {
				return result;
			}

			this.states = undefined;
		}

		throw new TunerStateError(`The Lua state ${stateName} moved again after a fresh state list`);
	}

	private async runOnce(stateName: string, lua: string): Promise<RunResult | typeof STALE> {
		const state = await this.findState(stateName);
		const id = ++this.lastId;
		// Main State is the only state whose prints have no prefix.
		const prefix = state.index === 0 ? "" : `${state.name}: `;
		const text = `CMD:${state.index}:${wrap(id, state.name, lua)}`;
		const { frame, lines, ending } = await this.enqueue(() => this.request(Tag.Command, text, { id, prefix }));
		const [result = ""] = frame.strings;

		// The index points at no state, such as after a quit to the main menu, or at another state.
		if (result === "ERR:Invalid Lua State" || ending?.kind === "state") {
			return STALE;
		}

		// A syntax error fails before the wrapper runs, so it has no markers.
		if (result.startsWith("ERR:")) {
			throw new TunerLuaError(result.slice("ERR:".length), lines);
		}

		if (ending?.kind === "error") {
			throw new TunerLuaError(ending.message, lines);
		}

		if (!ending) {
			throw new Error("The command ended without its end marker");
		}

		return { lines };
	}

	private async handshake(): Promise<void> {
		// No timeout, because nothing else can be sent until the game answers.
		await this.request(Tag.App, "APP:", { timed: false });
		this.ready = true;
		this.readyWaiters.splice(0).forEach((wake) => wake());
		this.emit("connected");
	}

	private async whenReady(): Promise<void> {
		if (!this.ready) {
			await new Promise<void>((resolve) => this.readyWaiters.push(resolve));
		}
	}

	private enqueue<T>(send: () => Promise<T>): Promise<T> {
		const result = this.queue.then(send);

		// A failed request must not stop the ones after it.
		this.queue = result.catch(() => {});

		return result;
	}

	// Sends one frame and resolves with the next frame that has the same tag.
	private request(tag: number, text: string, options: RequestOptions = {}): Promise<Reply> {
		const { id, prefix = "", timed = true } = options;

		return new Promise((resolve, reject) => {
			const request: Pending = {
				tag, id, prefix, lines: [], ending: undefined, resolve, reject, timer: undefined,
			};

			if (timed) {
				// The request stays in pending, so its late reply is still taken and dropped. Resolving a
				// promise that already rejected does nothing.
				request.timer = setTimeout(() => {
					reject(new TunerTimeoutError(`No reply from the tuner in ${this.timeoutMs} ms`));
				}, this.timeoutMs);
			}

			this.pending.push(request);
			this.connection.send(tag, [text]);
		});
	}

	private receive(frame: Frame): void {
		if (frame.tag === Tag.Output) {
			this.receiveOutput(frame.strings[1] ?? "");

			return;
		}

		const at = this.pending.findIndex((request) => request.tag === frame.tag);

		if (at === -1) {
			return;
		}

		const [request] = this.pending.splice(at, 1);

		clearTimeout(request.timer);

		request.resolve({ frame, lines: request.lines, ending: request.ending });
	}

	private receiveOutput(text: string): void {
		const marker = parseMarker(text);

		if (marker) {
			// A timed-out command's markers still arrive, so it opens and closes like any other.
			const command = this.pending.find((request) => request.id === marker.id);

			if (marker.kind === "begin") {
				this.openCommand = command;
			} else {
				if (command) {
					command.ending = marker.ending;
				}

				this.openCommand = undefined;
			}

			return;
		}

		const command = this.openCommand;

		// A print with a newline is several lines. Only the first has the state prefix.
		if (command && text.startsWith(command.prefix)) {
			command.lines.push(...text.slice(command.prefix.length).split("\n"));
		} else {
			text.split("\n").forEach((line) => this.emit("output", line));
		}
	}

	private drop(): void {
		const wasReady = this.ready;

		this.ready = false;
		this.states = undefined;
		this.openCommand = undefined;
		this.pending.splice(0).forEach((request) => {
			clearTimeout(request.timer);
			request.reject(new Error("Disconnected from the tuner"));
		});

		// A socket that closes before the handshake was never connected for the client's users.
		if (wasReady) {
			this.emit("disconnected");
		}
	}
}

// ["0", "Main State", "119", "InGame"] becomes [{ index: 0, name: "Main State" }, { index: 119, name: "InGame" }].
export function parseStates(strings: readonly string[]): LuaState[] {
	const states: LuaState[] = [];

	for (let at = 0; at + 1 < strings.length; at += 2) {
		states.push({ index: Number(strings[at]), name: strings[at + 1] });
	}

	return states;
}
