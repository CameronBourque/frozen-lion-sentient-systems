// The tuner protocol on top of a connection: the handshake, the Lua state list, state lookup by
// name, and running Lua. Requests go out one at a time, through one queue.
// docs/findings/tuner-protocol.md has the messages, and docs/findings/tuner-commands.md has how
// the game runs commands.

import { EventEmitter } from "node:events";
import { type ConnectionOptions, TunerConnection } from "./connection.js";
import { type Frame, Tag } from "./framing.js";

export const DEFAULT_TIMEOUT_MS = 10_000;

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

// "connected" fires once the game answers the handshake, not when the socket opens.
export interface ClientEvents {
	connected: [];
	disconnected: [];
}

// A request waiting for the next frame with its tag. A command also collects the output that
// arrives before its reply.
interface Pending {
	tag: number;
	// The state name and colon that the game puts before each printed line.
	prefix: string;
	lines: string[];
	resolve: (reply: Reply) => void;
	reject: (error: Error) => void;
	// True after a timeout. The reply still arrives later, and is dropped.
	abandoned: boolean;
	timer: NodeJS.Timeout | undefined;
}

interface Reply {
	frame: Frame;
	lines: string[];
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

	constructor(options: ClientOptions = {}) {
		super();
		this.connection = new TunerConnection(options);
		this.timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
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

	// Lists the states on the first lookup after each connect, because a new connection may come
	// after a load that changed the indexes.
	async findState(name: string): Promise<LuaState> {
		const states = this.states ?? await this.listStates();
		const matches = states.filter((state) => state.name === name);

		if (matches.length === 0) {
			throw new Error(`No Lua state is named ${name}`);
		}

		// SaveGameMenu is listed twice, and picking one could run Lua in the wrong state.
		if (matches.length > 1) {
			throw new Error(`${matches.length} Lua states are named ${name}`);
		}

		return matches[0];
	}

	// Runs Lua in the named state and resolves with the lines it printed.
	async run(stateName: string, lua: string): Promise<RunResult> {
		const state = await this.findState(stateName);
		// Main State is the only state whose prints have no prefix.
		const prefix = state.index === 0 ? "" : `${state.name}: `;
		const reply = await this.enqueue(() => this.request(Tag.Command, `CMD:${state.index}:${lua}`, prefix));
		const [result = ""] = reply.frame.strings;

		if (result.startsWith("ERR:")) {
			throw new TunerLuaError(result.slice("ERR:".length), reply.lines);
		}

		return { lines: reply.lines };
	}

	private async handshake(): Promise<void> {
		// No timeout, because nothing else can be sent until the game answers.
		await this.request(Tag.App, "APP:", "", false);
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
	private request(tag: number, text: string, prefix = "", timed = true): Promise<Reply> {
		return new Promise((resolve, reject) => {
			const request: Pending = { tag, prefix, lines: [], resolve, reject, abandoned: false, timer: undefined };

			if (timed) {
				request.timer = setTimeout(() => {
					request.abandoned = true;
					reject(new TunerTimeoutError(`No reply from the tuner in ${this.timeoutMs} ms`));
				}, this.timeoutMs);
			}

			this.pending.push(request);
			this.connection.send(tag, [text]);
		});
	}

	private receive(frame: Frame): void {
		if (frame.tag === Tag.Output) {
			// The game runs commands one at a time, so output belongs to the oldest command waiting,
			// even one that timed out.
			const command = this.pending.find((request) => request.tag === Tag.Command);
			const text = frame.strings[1] ?? "";

			command?.lines.push(text.startsWith(command.prefix) ? text.slice(command.prefix.length) : text);

			return;
		}

		const at = this.pending.findIndex((request) => request.tag === frame.tag);

		if (at === -1) {
			return;
		}

		const [request] = this.pending.splice(at, 1);

		clearTimeout(request.timer);

		if (!request.abandoned) {
			request.resolve({ frame, lines: request.lines });
		}
	}

	private drop(): void {
		const wasReady = this.ready;

		this.ready = false;
		this.states = undefined;
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
