// Tests for client.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { parseStates, TunerClient, TunerLuaError, TunerTimeoutError } from "../../src/tuner/client.js";
import { encodeFrame, Tag } from "../../src/tuner/framing.js";
import { errorReply, states } from "./captured.js";
import { FakeGame } from "./fake-game.js";

describe("TunerClient", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		game = await FakeGame.start();
		// A short timeout, so timeout tests take milliseconds.
		client = new TunerClient({ port: game.port, retryDelayMs: 10, timeoutMs: 100 });
	});

	afterEach(async () => {
		client.close();
		await game.close();
	});

	async function connect(): Promise<void> {
		client.connect();
		await once(client, "connected");
	}

	// How many frames with this tag the fake has received.
	function sent(tag: number): number {
		return game.received.filter((frame) => frame.tag === tag).length;
	}

	test("sends APP: first, and is connected once the game answers", async () => {
		await connect();

		expect(game.received).toEqual([{ tag: Tag.App, strings: ["APP:"] }]);
	});

	test("lists the states", async () => {
		await connect();

		expect(await client.listStates()).toEqual(states);
	});

	test("waits for the handshake before listing", async () => {
		const listed = client.listStates();

		client.connect();

		expect(await listed).toEqual(states);
		expect(game.received.map(({ tag }) => tag)).toEqual([Tag.App, Tag.StateList]);
	});

	test("finds a state by name, and lists the states once per connection", async () => {
		await connect();

		expect(await client.findState("InGame")).toEqual({ index: 119, name: "InGame" });
		expect(await client.findState("Main State")).toEqual({ index: 0, name: "Main State" });
		expect(sent(Tag.StateList)).toBe(1);
	});

	test("lists the states again after a reconnect", async () => {
		await connect();
		await client.findState("InGame");

		// Like a load that moved InGame to a new index.
		game.states = [{ index: 120, name: "InGame" }];

		const reconnected = once(client, "connected");

		await game.dropClient();
		await once(client, "disconnected");
		await reconnected;

		expect(await client.findState("InGame")).toEqual({ index: 120, name: "InGame" });
		expect(sent(Tag.StateList)).toBe(2);
	});

	test("rejects a name with no state or with more than one", async () => {
		await connect();

		await expect(client.findState("Nowhere")).rejects.toThrow("No Lua state is named Nowhere");
		await expect(client.findState("SaveGameMenu")).rejects.toThrow("2 Lua states are named SaveGameMenu");
	});

	test("rejects a request when the connection drops", async () => {
		await connect();
		game.silentTags.add(Tag.StateList);

		const listed = client.listStates();

		await once(game, "frame");
		await game.dropClient();

		await expect(listed).rejects.toThrow("Disconnected from the tuner");
	});

	test("retries the handshake after a drop before the game answered", async () => {
		const disconnected = vi.fn();

		client.on("disconnected", disconnected);
		game.silentTags.add(Tag.App);
		client.connect();
		await once(game, "frame");
		game.silentTags.clear();
		await game.dropClient();
		await once(client, "connected");

		// The first socket never finished the handshake, so the client was never connected.
		expect(disconnected).not.toHaveBeenCalled();
		expect(sent(Tag.App)).toBe(2);
	});

	test("defaults to a 10 s timeout", () => {
		// Reads the private field, because a client with no options would reach for the real game.
		expect(new TunerClient()).toMatchObject({ timeoutMs: 10_000 });
	});

	test("ignores output and replies that no request waits for", async () => {
		await connect();
		await game.print(119, "unprompted");
		await game.send(encodeFrame(Tag.Command, [""]));

		expect(await client.listStates()).toEqual(states);
	});
});

describe("TunerClient.run", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		game = await FakeGame.start();
		// Long enough for a test to answer by hand, and short enough for the timeout tests.
		client = new TunerClient({ port: game.port, retryDelayMs: 10, timeoutMs: 300 });
		client.connect();
		await once(client, "connected");
	});

	afterEach(async () => {
		client.close();
		await game.close();
	});

	// The commands the fake has received, without the CMD: and state index.
	function commands(): string[] {
		return game.received.filter(({ tag }) => tag === Tag.Command).map(({ strings }) => strings[0].replace(/^CMD:\d+:/, ""));
	}

	// An output frame and a tag 3 reply, the way the game answers a command in InGame.
	function answer(line: string, result = ""): Buffer {
		return Buffer.concat([encodeFrame(Tag.Output, ["O", `InGame: ${line}`]), encodeFrame(Tag.Command, [result])]);
	}

	test("sends the Lua to the state's index, and returns its lines without the prefix", async () => {
		game.onCommand = () => ({ output: ["hello", "world"] });

		expect(await client.run("InGame", "print(1)")).toEqual({ lines: ["hello", "world"] });
		expect(game.received.at(-1)).toEqual({ tag: Tag.Command, strings: ["CMD:119:print(1)"] });
	});

	test("returns Main State lines, which have no prefix", async () => {
		game.onCommand = () => ({ output: ["Main: not a prefix"] });

		expect(await client.run("Main State", "print(1)")).toEqual({ lines: ["Main: not a prefix"] });
	});

	test("keeps a line from another state whole", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await vi.waitFor(() => expect(commands()).toHaveLength(1));
		await game.print(11, "from an event handler");
		await game.send(answer("mine"));

		expect(await result).toEqual({ lines: ["from an event handler", "mine"] });
	});

	test("rejects with the game's error and the lines before it", async () => {
		game.onCommand = () => ({ output: ["before"], error: errorReply });

		const error = await client.run("InGame", "error(\"boom\")").catch((caught: unknown) => caught);

		expect(error).toBeInstanceOf(TunerLuaError);
		expect(error).toMatchObject({ message: errorReply.slice("ERR:".length), lines: ["before"] });
	});

	test("treats a reply with no strings as success", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await vi.waitFor(() => expect(commands()).toHaveLength(1));
		await game.send(Buffer.concat([encodeFrame(Tag.Output, ["O"]), encodeFrame(Tag.Command, [])]));

		// An output frame with no text gives an empty line.
		expect(await result).toEqual({ lines: [""] });
	});

	test("rejects a state name it can't find", async () => {
		await expect(client.run("Nowhere", "print(1)")).rejects.toThrow("No Lua state is named Nowhere");
		expect(commands()).toEqual([]);
	});

	test("sends one command at a time", async () => {
		game.onCommand = () => undefined;

		const results = [client.run("InGame", "first"), client.run("InGame", "second")];

		await vi.waitFor(() => expect(commands()).toEqual(["first"]));
		await game.send(answer("1"));
		await vi.waitFor(() => expect(commands()).toEqual(["first", "second"]));
		await game.send(answer("2"));

		expect(await Promise.all(results)).toEqual([{ lines: ["1"] }, { lines: ["2"] }]);
	});

	test("keeps going after a failed command", async () => {
		game.onCommand = (_state, lua) => (lua === "bad" ? { error: errorReply } : { output: ["ok"] });

		const failed = client.run("InGame", "bad");
		const passed = client.run("InGame", "good");

		await expect(failed).rejects.toThrow(TunerLuaError);
		expect(await passed).toEqual({ lines: ["ok"] });
	});

	test("times out, sends the next command, and drops the late reply", async () => {
		game.onCommand = () => undefined;

		const slow = client.run("InGame", "slow");

		await expect(slow).rejects.toThrow(TunerTimeoutError);

		const next = client.run("InGame", "next");

		await vi.waitFor(() => expect(commands()).toEqual(["slow", "next"]));
		// The game runs commands in order, so the slow command's output and reply come first.
		await game.send(Buffer.concat([answer("late"), answer("on time")]));

		expect(await next).toEqual({ lines: ["on time"] });
	});

	test("times out a state list request too", async () => {
		game.silentTags.add(Tag.StateList);

		await expect(client.listStates()).rejects.toThrow("No reply from the tuner in 300 ms");
	});

	test("rejects a command in flight when the connection drops", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await vi.waitFor(() => expect(commands()).toHaveLength(1));
		await game.dropClient();

		await expect(result).rejects.toThrow("Disconnected from the tuner");
	});
});

describe("parseStates", () => {
	test("pairs each index with its name", () => {
		expect(parseStates(["0", "Main State", "119", "InGame"])).toEqual([
			{ index: 0, name: "Main State" },
			{ index: 119, name: "InGame" },
		]);
	});

	test("drops an index with no name", () => {
		expect(parseStates(["0", "Main State", "1"])).toEqual([{ index: 0, name: "Main State" }]);
	});
});
