// Tests for trade.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { tradeRoute } from "../../src/actions/trade.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("tradeRoute", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("asks the core mod for the route to the city, named by its owner and ID", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_TradeRoute(0, 15728797, 5, 327680))";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] } })[lua] ?? {};

		expect(await tradeRoute(client, 0, 15728797, 5, 327680)).toEqual({ ok: true });
	});
});
