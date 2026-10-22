// Tests for connect.ts, against the fake game.

import { once } from "node:events";
import { afterEach, beforeEach, describe, expect, type MockInstance, test, vi } from "vitest";
import { CORE_STATE, onConnect } from "../src/connect.js";
import { TunerClient } from "../src/tuner/client.js";
import { Tag } from "../src/tuner/framing.js";
import { FakeGame } from "./tuner/fake-game.js";

describe("onConnect", () => {
	let game: FakeGame;
	let client: TunerClient;
	let logged: MockInstance<typeof console.log>;
	let warned: MockInstance<typeof console.warn>;

	beforeEach(async () => {
		game = await FakeGame.start();
		game.states = [{ index: 0, name: "Main State" }, { index: 130, name: CORE_STATE }];
		// A short timeout, so the timeout test takes milliseconds.
		client = new TunerClient({ port: game.port, retryDelayMs: 10, timeoutMs: 100 });
		logged = vi.spyOn(console, "log").mockImplementation(() => {});
		warned = vi.spyOn(console, "warn").mockImplementation(() => {});
		client.connect();
		await once(client, "connected");
	});

	afterEach(async () => {
		vi.restoreAllMocks();
		client.close();
		await game.close();
	});

	// The text of the only warning, without the time in front.
	function warning(): string {
		expect(warned).toHaveBeenCalledOnce();

		return String(warned.mock.calls[0][0]).replace(/^.*? {2}warning: /, "");
	}

	// Answers each core mod call with the lines given for it. Other Lua prints nothing.
	function answer(lines: Record<string, string[]>): void {
		game.onCommand = (_stateIndex, lua) => ({ output: lines[lua] ?? [] });
	}

	test("calls for the version and then the resync in the core mod's state, and logs both", async () => {
		answer({
			"SentientSystems_GetVersion()": ["[SENTIENTSYSTEMS] CORE_VERSION 0.1.0"],
			"SentientSystems_Resync()": ["[SENTIENTSYSTEMS] AGENT_TURN 0"],
		});

		await onConnect(client);

		expect(game.commands.map(({ stateIndex, lua }) => ({ stateIndex, lua }))).toEqual([
			{ stateIndex: 130, lua: "SentientSystems_GetVersion()" },
			{ stateIndex: 130, lua: "SentientSystems_Resync()" },
		]);
		expect(logged.mock.calls.map(([line]) => String(line).replace(/^.*? {2}/, ""))).toEqual(["core version 0.1.0", "turn 0"]);
		expect(warned).not.toHaveBeenCalled();
	});

	test("logs only the version between turns, when the resync prints nothing", async () => {
		answer({ "SentientSystems_GetVersion()": ["[SENTIENTSYSTEMS] CORE_VERSION 0.1.0"] });

		await onConnect(client);

		expect(logged).toHaveBeenCalledOnce();
		expect(warned).not.toHaveBeenCalled();
	});

	test("warns about a version line that doesn't parse", async () => {
		answer({ "SentientSystems_GetVersion()": ["[SENTIENTSYSTEMS] CORE_VERSION nil"] });

		await onConnect(client);

		expect(warning()).toMatch(/^CORE_VERSION needs one version/);
	});

	test("warns when the core mod's state isn't loaded", async () => {
		game.states = [{ index: 0, name: "Main State" }];

		await onConnect(client);

		expect(warning()).toMatch(/^The core mod's state SentientSystemsCore_UI isn't loaded\. Turn on Sentient Systems Core/);
	});

	test("warns when the game doesn't answer in time", async () => {
		game.onCommand = () => undefined;

		await onConnect(client);

		expect(warning()).toMatch(/^The game didn't answer the core mod check in time/);
	});

	test("warns with the game's error when the call fails in Lua, and skips the resync", async () => {
		game.onCommand = () => ({ luaError: "attempt to call a nil value" });

		await onConnect(client);

		expect(warning()).toBe("The core mod check failed in the game: attempt to call a nil value");
		expect(game.commands.map(({ lua }) => lua)).toEqual(["SentientSystems_GetVersion()"]);
	});

	test("warns when the resync fails after the version call works", async () => {
		game.onCommand = (_stateIndex, lua) => lua === "SentientSystems_Resync()"
			? { luaError: "attempt to index a nil value" }
			: { output: ["[SENTIENTSYSTEMS] CORE_VERSION 0.1.0"] };

		await onConnect(client);

		expect(logged).toHaveBeenCalledWith(expect.stringMatching(/ {2}core version 0\.1\.0$/));
		expect(warning()).toBe("The core mod check failed in the game: attempt to index a nil value");
	});

	test("warns when the game drops the connection during the call", async () => {
		game.silentTags.add(Tag.Command);

		const done = onConnect(client);

		await once(game, "frame");
		await game.dropClient();
		await done;

		expect(warning()).toBe("The core mod check failed: Disconnected from the tuner");
	});

	test("warns about a failure that isn't an Error", async () => {
		vi.spyOn(client, "run").mockRejectedValue("boom");

		await onConnect(client);

		expect(warning()).toBe("The core mod check failed: boom");
	});
});
