// Tests for world-congress.ts, against the fake game.

import { describe, expect, test } from "vitest";
import { voteInCongress } from "../../src/actions/world-congress.js";
import { startGame } from "../tuner/fake-game.js";

describe("voteInCongress", () => {
	test("passes the votes as a Lua list", async () => {
		const { game, client } = await startGame();
		const lua = "SentientSystems_VoteInCongress(0, {{ type = \"WC_EMERGENCY_BACKSTAB\", target = 10, votes = 3, against = false }, "
			+ "{ type = \"WC_EMERGENCY_REQUEST_AID\", target = 3, votes = 1, against = true }})";

		game.onCommand = (_stateIndex, command) => ({
			[`SentientSystems_Stash(${lua})`]: { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[command] ?? {};

		const votes = [{ type: "WC_EMERGENCY_BACKSTAB", target: 10, votes: 3 }, { type: "WC_EMERGENCY_REQUEST_AID", target: 3, votes: 1, against: true }];

		expect(await voteInCongress(client, 0, votes)).toEqual({ ok: true });
	});
});
