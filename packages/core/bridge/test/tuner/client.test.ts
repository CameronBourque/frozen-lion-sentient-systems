// Tests for client.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { parseStates, TunerClient } from "../../src/tuner/client.js";
import { Tag } from "../../src/tuner/framing.js";
import { states } from "./captured.js";
import { FakeGame } from "./fake-game.js";

describe("TunerClient", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		game = await FakeGame.start();
		client = new TunerClient({ port: game.port, retryDelayMs: 10 });
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

	test("ignores a frame that no request waits for", async () => {
		await connect();
		await game.print(119, "unprompted");

		expect(await client.listStates()).toEqual(states);
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
