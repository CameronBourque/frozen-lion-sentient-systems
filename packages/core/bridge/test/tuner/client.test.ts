// Tests for client.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { parseStates, TunerClient, TunerLuaError, TunerMissingStateError, TunerStateError, TunerTimeoutError } from "../../src/tuner/client.js";
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

	test("lists the states again after forgetStates, on the same connection", async () => {
		await connect();
		await client.findState("InGame");

		game.states = [{ index: 120, name: "InGame" }];
		client.forgetStates();

		expect(await client.findState("InGame")).toEqual({ index: 120, name: "InGame" });
		expect(sent(Tag.StateList)).toBe(2);
		expect(sent(Tag.App)).toBe(1);
	});

	test("rejects a name with no state or with more than one", async () => {
		await connect();

		await expect(client.findState("Nowhere")).rejects.toThrow("No Lua state is named Nowhere");
		await expect(client.findState("Nowhere")).rejects.toBeInstanceOf(TunerMissingStateError);
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
	let output: string[];

	beforeEach(async () => {
		game = await FakeGame.start();
		// Long enough for a test to answer by hand, and short enough for the timeout tests.
		client = new TunerClient({ port: game.port, retryDelayMs: 10, timeoutMs: 300 });
		output = [];
		client.on("output", (line) => output.push(line));
		client.connect();
		await once(client, "connected");
	});

	afterEach(async () => {
		client.close();
		await game.close();
	});

	// Resolves once the fake has received `count` commands in all.
	async function commandCount(count: number): Promise<void> {
		await vi.waitFor(() => expect(game.commands).toHaveLength(count));
	}

	function inGame(text: string): Buffer {
		return encodeFrame(Tag.Output, ["O", `InGame: ${text}`]);
	}

	// What the game sends back for a wrapped command in InGame that printed these lines.
	function answer(id: number | undefined, lines: string[], ending = "ok"): Buffer {
		return Buffer.concat([
			inGame(`@@ss:begin:${id}`),
			...lines.map(inGame),
			inGame(`@@ss:end:${id}:${ending}`),
			encodeFrame(Tag.Command, [""]),
		]);
	}

	test("sends the wrapped Lua to the state's index, and returns its lines without the prefix", async () => {
		game.onCommand = () => ({ output: ["hello", "world"] });

		expect(await client.run("InGame", "print(1)")).toEqual({ lines: ["hello", "world"] });
		expect(game.received.at(-1)?.strings[0]).toMatch(/^CMD:119:\(function\(\)\n/);
		expect(game.commands).toEqual([{ id: 1, stateIndex: 119, lua: "print(1)" }]);
	});

	test("runs in Main State, whose prints have no prefix", async () => {
		game.onCommand = () => ({ output: ["Main: not a prefix"] });

		expect(await client.run("Main State", "print(1)")).toEqual({ lines: ["Main: not a prefix"] });
	});

	test("splits a print with a newline into lines", async () => {
		game.onCommand = () => ({ output: ["first\nsecond"] });

		expect(await client.run("InGame", "print(1)")).toEqual({ lines: ["first", "second"] });
	});

	test("sends prints outside the markers and from other states to the output event", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await commandCount(1);
		await game.send(Buffer.concat([
			inGame("before"),
			inGame("@@ss:begin:1"),
			encodeFrame(Tag.Output, ["O", "PlotInfo: during"]),
			inGame("mine"),
			inGame("@@ss:end:1:ok"),
			encodeFrame(Tag.Command, [""]),
		]));

		expect(await result).toEqual({ lines: ["mine"] });
		expect(output).toEqual(["InGame: before", "PlotInfo: during"]);
	});

	test("emits each line of an unprompted print", async () => {
		await game.print(123, "first\nsecond");

		await vi.waitFor(() => expect(output).toEqual(["InvitePopup: first", "second"]));
	});

	test("drops the markers of a command it doesn't know", async () => {
		await game.send(Buffer.concat([inGame("@@ss:begin:98"), inGame("@@ss:end:99:ok")]));
		game.onCommand = () => ({ output: ["after"] });

		expect(await client.run("InGame", "print(1)")).toEqual({ lines: ["after"] });
		expect(output).toEqual([]);
	});

	test("rejects with a Lua error from the end marker and the lines before it", async () => {
		game.onCommand = () => ({ output: ["before"], luaError: "boom" });

		const error = await client.run("InGame", "error(\"boom\")").catch((caught: unknown) => caught);

		expect(error).toBeInstanceOf(TunerLuaError);
		expect(error).toMatchObject({ message: "boom", lines: ["before"] });
	});

	test("rejects with the game's error for a syntax error, which has no markers", async () => {
		game.onCommand = () => ({ error: errorReply });

		await expect(client.run("InGame", "local end")).rejects.toMatchObject({
			name: "TunerLuaError",
			message: errorReply.slice("ERR:".length),
			lines: [],
		});
	});

	test("rejects a command that ends without its end marker", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await commandCount(1);
		await game.send(encodeFrame(Tag.Command, [""]));

		await expect(result).rejects.toThrow("without its end marker");
	});

	test("treats a reply with no strings as success", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await commandCount(1);
		// An output frame with no text is an empty line, with no prefix.
		await game.send(Buffer.concat([
			inGame("@@ss:begin:1"),
			encodeFrame(Tag.Output, ["O"]),
			inGame("@@ss:end:1:ok"),
			encodeFrame(Tag.Command, []),
		]));

		expect(await result).toEqual({ lines: [] });
		expect(output).toEqual([""]);
	});

	test("lists the states again and retries when the index is gone", async () => {
		await client.run("InGame", "print(1)");
		// Like a quit to the main menu and a load that moved InGame.
		game.states = [{ index: 0, name: "Main State" }, { index: 120, name: "InGame" }];

		expect(await client.run("InGame", "print(2)")).toEqual({ lines: [] });
		expect(game.commands.map(({ stateIndex }) => stateIndex)).toEqual([119, 119, 120]);
	});

	test("lists the states again and retries when the index is another state", async () => {
		await client.run("InGame", "print(1)");
		game.states = [{ index: 0, name: "Main State" }, { index: 119, name: "PlotInfo" }, { index: 120, name: "InGame" }];

		expect(await client.run("InGame", "print(2)")).toEqual({ lines: [] });
		expect(game.commands.map(({ stateIndex }) => stateIndex)).toEqual([119, 119, 120]);
	});

	test("rejects when the state moves again after a fresh list", async () => {
		await client.run("InGame", "print(1)");
		game.states = [{ index: 120, name: "InGame" }];
		// The fake answers the fresh list with index 120, then moves InGame before the retry arrives.
		game.on("frame", ({ tag }: { tag: number }) => {
			if (tag === Tag.StateList) {
				game.states = [{ index: 121, name: "InGame" }];
			}
		});

		await expect(client.run("InGame", "print(2)")).rejects.toThrow(TunerStateError);
	});

	test("rejects a state name it can't find", async () => {
		await expect(client.run("Nowhere", "print(1)")).rejects.toThrow("No Lua state is named Nowhere");
		expect(game.commands).toEqual([]);
	});

	test("sends one command at a time", async () => {
		game.onCommand = () => undefined;

		const results = [client.run("InGame", "first"), client.run("InGame", "second")];

		await commandCount(1);
		await game.send(answer(game.commands[0].id, ["1"]));
		await commandCount(2);
		await game.send(answer(game.commands[1].id, ["2"]));

		expect(await Promise.all(results)).toEqual([{ lines: ["1"] }, { lines: ["2"] }]);
		expect(game.commands.map(({ lua }) => lua)).toEqual(["first", "second"]);
	});

	test("keeps going after a failed command", async () => {
		game.onCommand = (_state, lua) => (lua === "bad" ? { luaError: "boom" } : { output: ["ok"] });

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

		await commandCount(2);
		// The game runs commands in order, so the slow command's output and reply come first.
		await game.send(Buffer.concat([answer(game.commands[0].id, ["late"]), answer(game.commands[1].id, ["on time"])]));

		expect(await next).toEqual({ lines: ["on time"] });
		expect(output).toEqual([]);
	});

	test("times out a state list request too", async () => {
		game.silentTags.add(Tag.StateList);

		await expect(client.listStates()).rejects.toThrow("No reply from the tuner in 300 ms");
	});

	test("rejects a command in flight when the connection drops", async () => {
		game.onCommand = () => undefined;

		const result = client.run("InGame", "print(1)");

		await commandCount(1);
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
