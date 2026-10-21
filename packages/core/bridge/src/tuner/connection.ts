// Holds one TCP connection to the game's tuner socket, and turns its bytes into frames. It knows
// framing but not the protocol, so the handshake and commands are in client.ts.

import { EventEmitter } from "node:events";
import net from "node:net";
import { encodeFrame, type Frame, FrameDecoder } from "./framing.js";

export const DEFAULT_HOST = "127.0.0.1";
export const DEFAULT_PORT = 4318;

export interface ConnectionOptions {
	host?: string;
	port?: number;
}

// "disconnected" fires each time a socket closes, including an attempt that never connected,
// such as when the game isn't running. It carries the error, if there was one.
export interface ConnectionEvents {
	connected: [];
	disconnected: [error: Error | undefined];
	frame: [frame: Frame];
}

export class TunerConnection extends EventEmitter<ConnectionEvents> {
	private readonly host: string;
	private readonly port: number;
	// The socket from the moment connect() opens it until it closes.
	private socket: net.Socket | undefined;
	// The same socket, but only while it's connected.
	private openSocket: net.Socket | undefined;

	constructor(options: ConnectionOptions = {}) {
		super();
		this.host = options.host ?? DEFAULT_HOST;
		this.port = options.port ?? DEFAULT_PORT;
	}

	get connected(): boolean {
		return this.openSocket !== undefined;
	}

	connect(): void {
		// Does nothing while a socket is open or opening.
		if (this.socket) {
			return;
		}

		// A new decoder for each socket, so bytes left from a dropped socket can't join the next one.
		const decoder = new FrameDecoder();
		const socket = net.connect(this.port, this.host);
		let failure: Error | undefined;

		this.socket = socket;
		socket.on("connect", () => {
			this.openSocket = socket;
			this.emit("connected");
		});
		// Data is a Buffer unless something calls setEncoding, which nothing here does.
		socket.on("data", (chunk: Buffer) => {
			let frames: Frame[];

			try {
				frames = decoder.push(chunk);
			} catch (error) {
				// After a bad frame there's no way to find where the next one begins.
				socket.destroy(error as Error);

				return;
			}

			for (const frame of frames) {
				this.emit("frame", frame);
			}
		});
		// "close" always follows "error", so the error is kept for the disconnected event.
		socket.on("error", (error) => {
			failure = error;
		});
		socket.on("close", () => {
			this.socket = undefined;
			this.openSocket = undefined;
			this.emit("disconnected", failure);
		});
	}

	send(tag: number, strings: readonly string[]): void {
		if (!this.openSocket) {
			throw new Error("Not connected to the tuner");
		}

		this.openSocket.write(encodeFrame(tag, strings));
	}

	close(): void {
		this.socket?.destroy();
	}
}
