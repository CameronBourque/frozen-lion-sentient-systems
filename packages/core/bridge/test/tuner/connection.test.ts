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
		connection = new TunerConnection({ port: game.port });
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
		await game.waitForClient();
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
		game.send(bytes.subarray(0, 5));
		game.send(bytes.subarray(5));
		await vi.waitFor(() => expect(frames).toHaveBeenCalledOnce());

		expect(frames).toHaveBeenCalledWith({ tag: Tag.Output, strings: ["O", "InGame: hello"] });
	});

	test("emits each frame from one write", async () => {
		await connect();

		const frames = vi.fn();

		connection.on("frame", frames);
		game.send(Buffer.concat([encodeFrame(Tag.Output, ["O", "a"]), encodeFrame(Tag.Command, [""])]));
		await vi.waitFor(() => expect(frames).toHaveBeenCalledTimes(2));
	});

	test("drops the socket on a bad frame", async () => {
		await connect();

		// "O\0hello" with the last null missing.
		game.send(Buffer.from("07000000ffffffff4f0068656c6c6f", "hex"));

		const [error] = await next("disconnected");

		expect(error).toBeInstanceOf(FrameError);
		expect(connection.connected).toBe(false);
	});

	test("emits disconnected with no error when the game closes", async () => {
		await connect();
		game.dropClient();

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
		game.send(encodeFrame(Tag.Output, ["O", "lost"]).subarray(0, 6));
		game.dropClient();
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

	test("defaults to the game's tuner port", () => {
		// Reads the private fields, because a connection with no options would reach for the real game.
		expect(new TunerConnection()).toMatchObject({ host: "127.0.0.1", port: 4318 });
	});
});
