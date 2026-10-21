// A stand-in for the game's tuner socket, for the connection and client tests. It listens on a
// free local port and answers the handshake and commands the way the capture shows. Tests
// decide what each command does, because the fake runs no Lua, and can break things on purpose.

import { EventEmitter, once } from "node:events";
import net from "node:net";
import { encodeFrame, type Frame, FrameDecoder, Tag } from "../../src/tuner/framing.js";
import { appReply, states } from "./captured.js";

// What a command does. Output lines are given without the state prefix, which the fake adds.
// An error is the full ERR: text. Returning undefined sends no reply, for timeout tests.
export interface CommandResult {
	output?: string[];
	error?: string;
}

export type CommandHandler = (stateIndex: number, lua: string) => CommandResult | undefined;

// "CMD:119:print(1)" splits into the state index and the Lua. The s flag lets the Lua span lines.
const commandPattern = /^CMD:(\d+):(.*)$/s;

// Emits "client" when a client connects, and "frame" after each frame it receives.
export class FakeGame extends EventEmitter {
	readonly received: Frame[] = [];
	onCommand: CommandHandler = () => ({});
	private client: net.Socket | undefined;

	private constructor(private readonly server: net.Server) {
		super();
	}

	static async start(): Promise<FakeGame> {
		const server = net.createServer();
		const game = new FakeGame(server);

		// The game takes one client at a time.
		server.maxConnections = 1;
		server.on("connection", (socket) => game.accept(socket));
		server.listen(0, "127.0.0.1");
		await once(server, "listening");

		return game;
	}

	get port(): number {
		return (this.server.address() as net.AddressInfo).port;
	}

	get connected(): boolean {
		return this.client !== undefined;
	}

	async waitForClient(): Promise<void> {
		if (!this.client) {
			await once(this, "client");
		}
	}

	// An output frame the way the game prints it, such as an event handler's print.
	print(stateIndex: number, text: string): void {
		this.send(outputFrame(stateIndex, text));
	}

	// Raw bytes, for split, merged, or broken frames.
	send(bytes: Buffer): void {
		this.client?.write(bytes);
	}

	// Like the game closing or crashing.
	dropClient(): void {
		this.client?.destroy();
	}

	async close(): Promise<void> {
		this.dropClient();
		await new Promise((resolve) => this.server.close(resolve));
	}

	private accept(socket: net.Socket): void {
		const decoder = new FrameDecoder();

		this.client = socket;
		// A client that resets the socket is normal in tests, not a failure.
		socket.on("error", () => {});
		socket.on("close", () => {
			this.client = undefined;
		});
		// Data is a Buffer unless something calls setEncoding, which nothing here does.
		socket.on("data", (chunk: Buffer) => {
			for (const frame of decoder.push(chunk)) {
				this.received.push(frame);
				this.reply(frame);
				this.emit("frame", frame);
			}
		});
		this.emit("client");
	}

	private reply(frame: Frame): void {
		if (frame.tag === Tag.App) {
			this.send(encodeFrame(Tag.App, appReply));
		} else if (frame.tag === Tag.StateList) {
			this.send(encodeFrame(Tag.StateList, states.flatMap(({ index, name }) => [String(index), name])));
		} else if (frame.tag === Tag.Command) {
			this.runCommand(frame.strings[0] ?? "");
		}
	}

	private runCommand(text: string): void {
		const match = commandPattern.exec(text);

		if (!match) {
			return;
		}

		const stateIndex = Number(match[1]);
		const result = this.onCommand(stateIndex, match[2]);

		if (!result) {
			return;
		}

		const output = (result.output ?? []).map((line) => outputFrame(stateIndex, line));
		const end = encodeFrame(Tag.Command, [result.error ?? ""]);

		// One write, because the game sent output and its tag 3 reply in one TCP segment.
		this.send(Buffer.concat([...output, end]));
	}
}

// Every state but Main State puts its name before printed text, such as "InGame: hello".
function outputFrame(stateIndex: number, text: string): Buffer {
	const name = states.find(({ index }) => index === stateIndex)?.name;
	const prefix = stateIndex === 0 || !name ? "" : `${name}: `;

	return encodeFrame(Tag.Output, ["O", `${prefix}${text}`]);
}
