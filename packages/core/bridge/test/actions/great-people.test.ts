// Tests for great-people.ts, against the fake game.

import { beforeEach, describe, expect, test } from "vitest";
import { passGreatPerson, patronizeGreatPerson, recruitGreatPerson } from "../../src/actions/great-people.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

describe("recruitGreatPerson, passGreatPerson, and patronizeGreatPerson", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	test("ask the core mod to recruit or pass the great person", async () => {
		const ok = { output: ["{\"ok\":true}"] };

		game.onCommand = (_stateIndex, lua) => ({
			"SentientSystems_Stash(SentientSystems_RecruitGreatPerson(0, \"GREAT_PERSON_INDIVIDUAL_ARYABHATA\"))": { output: ["1"] },
			"SentientSystems_Stash(SentientSystems_PassGreatPerson(0, \"GREAT_PERSON_INDIVIDUAL_HOMER\"))": { output: ["1"] },
			"SentientSystems_PrintPiece(1)": ok,
		})[lua] ?? {};

		expect(await recruitGreatPerson(client, 0, "GREAT_PERSON_INDIVIDUAL_ARYABHATA")).toEqual({ ok: true });
		expect(await passGreatPerson(client, 0, "GREAT_PERSON_INDIVIDUAL_HOMER")).toEqual({ ok: true });
	});

	test("pass the yield to patronize, and return the core mod's reason", async () => {
		const stash = "SentientSystems_Stash(SentientSystems_PatronizeGreatPerson(0, \"GREAT_PERSON_INDIVIDUAL_SUN_TZU\", \"gold\"))";
		const reason = "You can't afford GREAT_PERSON_INDIVIDUAL_SUN_TZU with gold. It costs 650.";

		game.onCommand = (_stateIndex, lua) => ({ [stash]: { output: ["1"] }, "SentientSystems_PrintPiece(1)": { output: [JSON.stringify({ ok: false, reason })] } })[lua] ?? {};

		expect(await patronizeGreatPerson(client, 0, "GREAT_PERSON_INDIVIDUAL_SUN_TZU", "gold")).toEqual({ ok: false, reason });
	});
});
