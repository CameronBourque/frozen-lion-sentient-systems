// The tuner protocol on top of a connection: the handshake, the Lua state list, and state lookup
// by name. docs/findings/tuner-protocol.md has the messages.

import { EventEmitter } from "node:events";
import { type ConnectionOptions, TunerConnection } from "./connection.js";
import { type Frame, Tag } from "./framing.js";

export interface LuaState {
	index: number;
	name: string;
}

// "connected" fires once the game answers the handshake, not when the socket opens.
export interface ClientEvents {
	connected: [];
	disconnected: [];
}

// A request waiting for the next frame with its tag.
interface Pending {
	tag: number;
	resolve: (frame: Frame) => void;
	reject: (error: Error) => void;
}

export class TunerClient extends EventEmitter<ClientEvents> {
	private readonly connection: TunerConnection;
	private readonly pending: Pending[] = [];
	// Calls waiting for the handshake to finish.
	private readonly readyWaiters: (() => void)[] = [];
	private ready = false;
	// The state list from the first lookup on this connection.
	private states: LuaState[] | undefined;

	constructor(options: ConnectionOptions = {}) {
		super();
		this.connection = new TunerConnection(options);
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

		const reply = await this.request(Tag.StateList, "LSQ:");

		this.states = parseStates(reply.strings);

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

	private async handshake(): Promise<void> {
		await this.request(Tag.App, "APP:");
		this.ready = true;
		this.readyWaiters.splice(0).forEach((wake) => wake());
		this.emit("connected");
	}

	private async whenReady(): Promise<void> {
		if (!this.ready) {
			await new Promise<void>((resolve) => this.readyWaiters.push(resolve));
		}
	}

	// Sends one frame and resolves with the next frame that has the same tag.
	private request(tag: number, text: string): Promise<Frame> {
		return new Promise((resolve, reject) => {
			this.pending.push({ tag, resolve, reject });
			this.connection.send(tag, [text]);
		});
	}

	private receive(frame: Frame): void {
		const at = this.pending.findIndex((request) => request.tag === frame.tag);

		// Output frames have no request.
		if (at !== -1) {
			this.pending.splice(at, 1)[0].resolve(frame);
		}
	}

	private drop(): void {
		const wasReady = this.ready;

		this.ready = false;
		this.states = undefined;
		this.pending.splice(0).forEach((request) => request.reject(new Error("Disconnected from the tuner")));

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
