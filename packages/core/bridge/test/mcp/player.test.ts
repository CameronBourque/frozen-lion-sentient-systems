// Tests for mcp/player.ts, against the fake game.

import { expect, test } from "vitest";
import { localPlayer } from "../../src/mcp/player.js";
import { startGame } from "../tuner/fake-game.js";

test("localPlayer asks the core mod's state for the local player", async () => {
	const { game, client } = await startGame();

	game.onCommand = (_stateIndex, lua) => (lua === "print(Game.GetLocalPlayer())" ? { output: ["2"] } : {});

	expect(await localPlayer(client)()).toEqual({ ok: true, playerID: 2 });
	expect(game.commands[0]).toMatchObject({ stateIndex: 130 });
});

test("localPlayer fails on a reply that isn't a player ID", async () => {
	const { game, client } = await startGame();

	game.onCommand = () => ({ output: ["-1"] });

	expect(await localPlayer(client)()).toEqual({ ok: false, error: "Game.GetLocalPlayer() printed [\"-1\"], not a player ID" });
});

test("localPlayer says what to do when the core mod isn't loaded", async () => {
	const { client } = await startGame([{ index: 0, name: "Main State" }]);

	expect(await localPlayer(client)()).toMatchObject({ ok: false, error: expect.stringContaining("Turn on Sentient Systems Core") as unknown });
});
