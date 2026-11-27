// Tests for agents/game-wait.ts: the wait for a game that stops answering,
// through the fake game.

import { beforeEach, expect, test, vi } from "vitest";
import { waitForGame } from "../../src/agents/game-wait.js";
import { Logger } from "../../src/log.js";
import { type TunerClient, TunerTimeoutError } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

const WAIT_MS = 5;

let game: FakeGame;
let client: TunerClient;
let logger: Logger;

beforeEach(async () => {
	({ game, client } = await startGame());
	logger = new Logger("error");
});

// The game answers nothing for its first silent checks. The fake game never
// sends a late reply, as the real one does, so the checks fail here.
function silentFor(silent: number): void {
	let count = 0;
	const run = client.run.bind(client);

	vi.spyOn(client, "run").mockImplementation((state, lua) => {
		count += 1;

		return count > silent ? run(state, lua) : Promise.reject(new TunerTimeoutError("No reply from the tuner in 100 ms"));
	});
}

test("a game that answers needs no wait", async () => {
	const info = vi.spyOn(logger, "info");

	expect(await waitForGame(client, logger, 3, undefined, WAIT_MS)).toBe(true);
	expect(game.commands).toHaveLength(1);
	expect(info).not.toHaveBeenCalled();
});

test("a Lua error still counts as an answer", async () => {
	game.onCommand = () => ({ luaError: "attempt to call a nil value" });

	expect(await waitForGame(client, logger, 3, undefined, WAIT_MS)).toBe(true);
});

test("a silent game is checked again until it answers", async () => {
	const info = vi.spyOn(logger, "info");

	silentFor(2);

	expect(await waitForGame(client, logger, 3, undefined, WAIT_MS)).toBe(true);
	expect(info).toHaveBeenCalledWith("game_silent", "The game doesn't answer, so player 3's turn waits for it", { player: 3 });
	expect(info).toHaveBeenCalledWith("game_answers", "The game answers again, so player 3's turn goes on", { player: 3 });
});

test("an abort ends the wait", async () => {
	const controller = new AbortController();

	silentFor(Infinity);
	vi.spyOn(logger, "info").mockImplementation((event) => {
		if (event === "game_silent") {
			controller.abort();
		}
	});

	expect(await waitForGame(client, logger, 3, controller.signal, WAIT_MS)).toBe(false);
});
