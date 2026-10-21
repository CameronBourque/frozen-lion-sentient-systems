// Holds one TCP connection to the game's tuner socket, and turns its bytes into frames. After
// connect(), it reconnects with backoff each time the socket closes, until close(). It knows
// framing but not the protocol, so the handshake and commands are in client.ts.

import { EventEmitter } from "node:events";
import net from "node:net";
import { encodeFrame, type Frame, FrameDecoder } from "./framing.js";

export const DEFAULT_HOST = "127.0.0.1";
export const DEFAULT_PORT = 4318;
// The wait before the first retry. It doubles after each failed attempt, up to the maximum.
export const DEFAULT_RETRY_DELAY_MS = 500;
export const DEFAULT_MAX_RETRY_DELAY_MS = 10_000;

export interface ConnectionOptions {
	host?: string;
	port?: number;
	retryDelayMs?: number;
	maxRetryDelayMs?: number;
}

// "disconnected" fires each time a socket closes, including an attempt that never connected,
// such as when the game isn't running. It carries the error, if there was one. "retrying" fires
// after it with the wait before the next attempt.
export interface ConnectionEvents {
	connected: [];
	disconnected: [error: Error | undefined];
	retrying: [delayMs: number];
	frame: [frame: Frame];
}

export class TunerConnection extends EventEmitter<ConnectionEvents> {
	private readonly host: string;
	private readonly port: number;
	private readonly retryDelayMs: number;
	private readonly maxRetryDelayMs: number;
	private nextRetryDelayMs: number;
	private retryTimer: NodeJS.Timeout | undefined;
	// True from connect() until close(), while the connection should keep retrying.
	private wanted = false;
	// The socket from the moment it opens until it closes.
	private socket: net.Socket | undefined;
	// The same socket, but only while it's connected.
	private openSocket: net.Socket | undefined;

	constructor(options: ConnectionOptions = {}) {
		super();
		this.host = options.host ?? DEFAULT_HOST;
		this.port = options.port ?? DEFAULT_PORT;
		this.retryDelayMs = options.retryDelayMs ?? DEFAULT_RETRY_DELAY_MS;
		this.maxRetryDelayMs = options.maxRetryDelayMs ?? DEFAULT_MAX_RETRY_DELAY_MS;
		this.nextRetryDelayMs = this.retryDelayMs;
	}

	get connected(): boolean {
		return this.openSocket !== undefined;
	}

	connect(): void {
		this.wanted = true;
		// Tries at once, even during the wait before a retry.
		clearTimeout(this.retryTimer);
		this.open();
	}

	send(tag: number, strings: readonly string[]): void {
		if (!this.openSocket) {
			throw new Error("Not connected to the tuner");
		}

		this.openSocket.write(encodeFrame(tag, strings));
	}

	close(): void {
		this.wanted = false;
		clearTimeout(this.retryTimer);
		this.socket?.destroy();
	}

	private open(): void {
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
			this.nextRetryDelayMs = this.retryDelayMs;
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

			// A disconnected listener may have called close().
			if (this.wanted) {
				this.scheduleRetry();
			}
		});
	}

	private scheduleRetry(): void {
		const delayMs = this.nextRetryDelayMs;

		this.nextRetryDelayMs = Math.min(delayMs * 2, this.maxRetryDelayMs);
		this.retryTimer = setTimeout(() => this.open(), delayMs);
		this.emit("retrying", delayMs);
	}
}
