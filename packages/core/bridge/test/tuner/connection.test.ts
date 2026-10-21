// Tests for connection.ts, against the fake game.

import { once } from "node:events";
import net from "node:net";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { type ConnectionEvents, TunerConnection } from "../../src/tuner/connection.js";
import { encodeFrame, FrameError, Tag } from "../../src/tuner/framing.js";
import { appReply } from "./captured.js";
import { FakeGame } from "./fake-game.js";

describe("TunerConnection", () => {
	let game: FakeGame;
	let connection: TunerConnection;

	beforeEach(async () => {
		game = await FakeGame.start();
		// Short waits, so retry tests take milliseconds.
		connection = new TunerConnection({ port: game.port, retryDelayMs: 10, maxRetryDelayMs: 40 });
	});

	afterEach(async () => {
		vi.restoreAllMocks();
		connection.close();
		await game.close();
	});

	// once() gives back any[], so this gives the event's arguments their types.
	function next<Event extends keyof ConnectionEvents>(event: Event): Promise<ConnectionEvents[Event]> {
		return once(connection, event) as Promise<ConnectionEvents[Event]>;
	}

	async function connect(): Promise<void> {
		connection.connect();
		await once(connection, "connected");
	}

	test("connects, sends a frame, and emits the reply", async () => {
		await connect();
		expect(connection.connected).toBe(true);

		connection.send(Tag.App, ["APP:"]);

		const [frame] = await next("frame");

		expect(frame).toEqual({ tag: Tag.App, strings: appReply });
	});

	test("emits one frame for a frame split across two writes", async () => {
		await connect();

		const bytes = encodeFrame(Tag.Output, ["O", "InGame: hello"]);
		const frames = vi.fn();

		connection.on("frame", frames);
		await game.send(bytes.subarray(0, 5));
		await game.send(bytes.subarray(5));
		await vi.waitFor(() => expect(frames).toHaveBeenCalledOnce());

		expect(frames).toHaveBeenCalledWith({ tag: Tag.Output, strings: ["O", "InGame: hello"] });
	});

	test("emits each frame from one write", async () => {
		await connect();

		const frames = vi.fn();

		connection.on("frame", frames);
		await game.send(Buffer.concat([encodeFrame(Tag.Output, ["O", "a"]), encodeFrame(Tag.Command, [""])]));
		await vi.waitFor(() => expect(frames).toHaveBeenCalledTimes(2));
	});

	test("drops the socket on a bad frame", async () => {
		await connect();

		// "O\0hello" with the last null missing.
		await game.send(Buffer.from("07000000ffffffff4f0068656c6c6f", "hex"));

		const [error] = await next("disconnected");

		expect(error).toBeInstanceOf(FrameError);
		expect(connection.connected).toBe(false);
	});

	test("emits disconnected with no error when the game closes", async () => {
		await connect();
		await game.dropClient();

		const [error] = await next("disconnected");

		expect(error).toBeUndefined();
		expect(connection.connected).toBe(false);
	});

	test("emits disconnected with the error when nothing is listening", async () => {
		// A port that was free a moment ago, like the game's port while the game isn't running.
		await game.close();
		connection.connect();

		const [error] = await next("disconnected");

		expect(error).toMatchObject({ code: "ECONNREFUSED" });
	});

	test("starts each socket with an empty decoder", async () => {
		await connect();
		// Half a frame, then the game closes.
		await game.send(encodeFrame(Tag.Output, ["O", "lost"]).subarray(0, 6));
		await game.dropClient();
		await once(connection, "disconnected");
		await connect();

		connection.send(Tag.App, ["APP:"]);

		const [frame] = await next("frame");

		expect(frame).toEqual({ tag: Tag.App, strings: appReply });
	});

	test("ignores connect while a socket is open or opening", async () => {
		const opened = vi.spyOn(net, "connect");

		connection.connect();
		connection.connect();
		await once(connection, "connected");
		connection.connect();

		expect(opened).toHaveBeenCalledOnce();
	});

	test("throws on send while not connected", () => {
		expect(() => connection.send(Tag.App, ["APP:"])).toThrow("Not connected");
	});

	test("closes the socket on close, and does nothing when there is none", async () => {
		connection.close();
		await connect();
		connection.close();
		await once(connection, "disconnected");

		expect(connection.connected).toBe(false);
	});

	test("defaults to the game's tuner port and retry waits", () => {
		// Reads the private fields, because a connection with no options would reach for the real game.
		expect(new TunerConnection()).toMatchObject({
			host: "127.0.0.1",
			port: 4318,
			retryDelayMs: 500,
			maxRetryDelayMs: 10_000,
		});
	});

	describe("reconnect", () => {
		// Stops the fake, so the port is free, like the game's port while the game isn't running.
		async function stopGame(): Promise<number> {
			const port = game.port;

			await game.close();

			return port;
		}

		test("connects once the game starts", async () => {
			const port = await stopGame();

			connection.connect();
			await next("retrying");
			// Wait first, because a retry can connect before start() returns.
			const connected = next("connected");

			game = await FakeGame.start(port);
			await connected;

			expect(connection.connected).toBe(true);
		});

		test("reconnects after the game closes", async () => {
			await connect();
			await game.dropClient();
			await next("connected");

			expect(connection.connected).toBe(true);
		});

		test("doubles the wait up to the maximum, and resets it after a connection", async () => {
			const port = await stopGame();
			const delays: number[] = [];

			connection.on("retrying", (delayMs) => delays.push(delayMs));
			connection.connect();
			await vi.waitFor(() => expect(delays.length).toBeGreaterThanOrEqual(4), { interval: 5 });
			expect(delays.slice(0, 4)).toEqual([10, 20, 40, 40]);

			// Wait first, because a retry can connect before start() returns.
			const connected = next("connected");

			game = await FakeGame.start(port);
			await connected;
			delays.length = 0;
			await game.dropClient();
			await next("connected");

			expect(delays).toEqual([10]);
		});

		test("stops retrying after close", async () => {
			await stopGame();

			const opened = vi.spyOn(net, "connect");

			connection.connect();
			await next("retrying");
			connection.close();
			// Longer than the 10 ms wait, so a retry that wasn't cancelled would have run.
			await new Promise((resolve) => setTimeout(resolve, 30));

			expect(opened).toHaveBeenCalledOnce();
		});

		test("doesn't retry when a disconnected listener calls close", async () => {
			const retrying = vi.fn();

			await stopGame();
			connection.on("disconnected", () => connection.close());
			connection.on("retrying", retrying);
			connection.connect();
			await next("disconnected");

			expect(retrying).not.toHaveBeenCalled();
		});

		test("tries at once when connect is called during the wait", async () => {
			const port = await stopGame();
			const patient = new TunerConnection({ port, retryDelayMs: 60_000 });

			patient.connect();

			const [delayMs] = await (once(patient, "retrying") as Promise<ConnectionEvents["retrying"]>);

			expect(delayMs).toBe(60_000);
			game = await FakeGame.start(port);
			patient.connect();
			await once(patient, "connected");
			patient.close();
		});
	});
});
