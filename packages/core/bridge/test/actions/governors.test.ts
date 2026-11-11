// Tests for governors.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { appointGovernor, assignGovernor, promoteGovernor } from "../../src/actions/governors.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("the governor actions", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("ask the core mod to appoint, promote, and assign the governor", async () => {
		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_AppointGovernor(0, \"GOVERNOR_THE_EDUCATOR\"))": { output: ["1"] },
			"SentientSystems_Stash(SentientSystems_PromoteGovernor(0, \"GOVERNOR_THE_EDUCATOR\", \"GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN\"))": { output: ["1"] },
			"SentientSystems_Stash(SentientSystems_AssignGovernor(0, \"GOVERNOR_THE_EDUCATOR\", 0, 65536))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: ["{\"ok\":true}"] },
		})[lua] ?? {};

		expect(await appointGovernor(client, 0, "GOVERNOR_THE_EDUCATOR")).toEqual({ ok: true });
		expect(await promoteGovernor(client, 0, "GOVERNOR_THE_EDUCATOR", "GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN")).toEqual({ ok: true });
		expect(await assignGovernor(client, 0, "GOVERNOR_THE_EDUCATOR", 0, 65536)).toEqual({ ok: true });
	});

	test("return the core mod's reason", async () => {
		const reason = "You have no governor title to spend. The governors choice lists appointments once you do.";

		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_AppointGovernor(0, \"GOVERNOR_THE_DEFENDER\"))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] },
		})[lua] ?? {};

		expect(await appointGovernor(client, 0, "GOVERNOR_THE_DEFENDER")).toEqual({ ok: false, reason });
	});
});
