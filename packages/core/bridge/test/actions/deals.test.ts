// Tests for deals.ts, against the fake game.

import { describe, expect, test } from "vitest";
import { declareWar, proposePeace, respondToDeal } from "../../src/actions/deals.js";
import { startGame } from "../tuner/fake-game.js";

describe("respondToDeal", () => {
	test("passes the players and the answer", async () => {
		const { game, client } = await startGame();
		const lua = "SentientSystems_RespondToDeal(0, 4, false)";

		game.onCommand = (_stateIndex, command) => ({
			[`SentientSystems_Stash(${lua})`]: { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[command] ?? {};

		expect(await respondToDeal(client, 0, 4, false)).toEqual({ ok: true });
	});
});

describe("declareWar", () => {
	test("passes the players", async () => {
		const { game, client } = await startGame();
		const lua = "SentientSystems_DeclareWar(0, 12)";

		game.onCommand = (_stateIndex, command) => ({
			[`SentientSystems_Stash(${lua})`]: { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[command] ?? {};

		expect(await declareWar(client, 0, 12)).toEqual({ ok: true });
	});
});

describe("proposePeace", () => {
	const PROPOSE = "SentientSystems_ProposePeace(0, 10)";
	const RESULT = "SentientSystems_GetPeaceResult(0, 10)";
	const AT_WAR = "{\"ok\":false,\"reason\":\"Player 10 hasn't accepted peace. You are still at war.\"}";
	const WAIT = { timeoutMs: 100, intervalMs: 10 };

	// Starts a fake game where the proposal gives the result proposed, and the
	// war ends after the number of reads given, or never for undefined. Each
	// stash holds one piece, the result of the last call stashed.
	async function startPeace(proposed: string, readsUntilPeace?: number) {
		const { game, client } = await startGame();
		let reads = 0;
		let stashed = "";

		game.onCommand = (_stateIndex, command) => {
			if (command === `SentientSystems_Stash(${PROPOSE})`) {
				stashed = proposed;
			} else if (command === `SentientSystems_Stash(${RESULT})`) {
				reads++;
				stashed = readsUntilPeace !== undefined && reads >= readsUntilPeace ? "{\"ok\":true}" : AT_WAR;
			} else if (command === "SentientSystems_PrintPiece(1)") {
				return { output: [stashed] };
			} else {
				return {};
			}

			return { output: ["1"] };
		};

		return { client, reads: () => reads };
	}

	test("waits until the war ends", async () => {
		const { client, reads } = await startPeace("{\"ok\":true}", 3);

		expect(await proposePeace(client, 0, 10, WAIT)).toEqual({ ok: true });
		expect(reads()).toBe(3);
	});

	test("fails when the war goes on after the wait", async () => {
		const { client } = await startPeace("{\"ok\":true}");

		expect(await proposePeace(client, 0, 10, WAIT)).toEqual({ ok: false, reason: "Player 10 hasn't accepted peace. You are still at war." });
	});

	test("returns a refused proposal without waiting", async () => {
		const refused = "{\"ok\":false,\"reason\":\"You aren't at war with player 10.\"}";
		const { client, reads } = await startPeace(refused);

		expect(await proposePeace(client, 0, 10, WAIT)).toEqual({ ok: false, reason: "You aren't at war with player 10." });
		expect(reads()).toBe(0);
	});
});
