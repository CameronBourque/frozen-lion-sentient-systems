// Tests for lookup.ts, against the fake game. The stash's failures are tested
// in state.test.ts, through readState, and the schemas in contract.test.ts.

import { beforeEach, describe, expect, test } from "vitest";
import { lookup, lookupPage, lookupSection, lookupSections, luaString } from "../../src/lookup/lookup.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";

const PAGE = { sectionID: "UNITS", pageID: "UNIT_SETTLER", title: "Settler", text: "## Traits\n- 2 Movement Points" };
const SECTION = { sectionID: "CONCEPTS", title: "Concepts", groups: [{ title: "Movement", pages: [{ pageID: "MOVEMENT_1", title: "Movement Points" }] }] };

describe("luaString", () => {
	test("quotes plain text as it is", () => {
		expect(luaString("zone of control")).toBe("\"zone of control\"");
	});

	test("escapes quotes, backslashes, and control characters as \\ddd", () => {
		expect(luaString("a\"b\\c\nd\u007f")).toBe("\"a\\034b\\092c\\010d\\127\"");
	});

	test("keeps text in other languages as it is", () => {
		expect(luaString("Warak’aq")).toBe("\"Warak’aq\"");
	});
});

describe("the lookup calls", () => {
	let game: FakeGame;
	let client: TunerClient;

	beforeEach(async () => {
		({ game, client } = await startGame());
	});

	// Answers the stash of the call with the value as JSON. Other Lua prints
	// nothing.
	function answer(call: string, value: unknown): void {
		game.onCommand = (_stateIndex, lua) => {
			if (lua === `SentientSystems_Stash(${call})`) {
				return { output: ["1"] };
			}

			return lua === "SentientSystems_PrintPiece(1)" ? { output: [JSON.stringify(value)] } : {};
		};
	}

	test("lookup searches for the query, escaped, in the core mod's state", async () => {
		const search = { results: [{ sectionID: "CONCEPTS", pageID: "MOVEMENT_3", title: "Zone of Control", snippet: "Many combat units exert a \"Zone of Control\"." }] };

		answer("SentientSystems_Lookup(\"\\034zone\\034\")", search);

		expect(await lookup(client, "\"zone\"")).toMatchObject({ ok: true, value: search });
		expect(game.commands[0]).toMatchObject({ stateIndex: 130 });
	});

	test("lookupPage reads a page by its ID alone", async () => {
		answer("SentientSystems_LookupPage(\"UNIT_SETTLER\")", PAGE);

		expect(await lookupPage(client, "UNIT_SETTLER")).toMatchObject({ ok: true, value: PAGE });
	});

	test("lookupPage passes the section when it is given", async () => {
		const intro = { sectionID: "UNITS", pageID: "INTRO", title: "Introduction" };

		answer("SentientSystems_LookupPage(\"INTRO\", \"UNITS\")", intro);

		expect(await lookupPage(client, "INTRO", "UNITS")).toMatchObject({ ok: true, value: intro });
	});

	test("lookupPage fails with the core mod's error for a page it can't find", async () => {
		const error = "INTRO is in more than one section. Give one of: CONCEPTS, UNITS.";

		answer("SentientSystems_LookupPage(\"INTRO\")", { error });

		expect(await lookupPage(client, "INTRO")).toEqual({ ok: false, error });
	});

	test("lookupSections lists the sections", async () => {
		const sections = { sections: [{ sectionID: "CONCEPTS", title: "Concepts", pageCount: 132 }] };

		answer("SentientSystems_LookupSections()", sections);

		expect(await lookupSections(client)).toMatchObject({ ok: true, value: sections });
	});

	test("lookupSection lists a section's pages, or fails with the core mod's error", async () => {
		answer("SentientSystems_LookupSection(\"CONCEPTS\")", SECTION);

		expect(await lookupSection(client, "CONCEPTS")).toMatchObject({ ok: true, value: SECTION });

		const error = "No section has the ID LEADERS. Give one of: CONCEPTS.";

		answer("SentientSystems_LookupSection(\"LEADERS\")", { error });

		expect(await lookupSection(client, "LEADERS")).toEqual({ ok: false, error });
	});

	test("names the page in a game error", async () => {
		game.onCommand = () => ({ luaError: "attempt to index a nil value" });

		expect(await lookupPage(client, "UNIT_SETTLER")).toEqual({
			ok: false,
			error: "The Civilopedia page request failed in the game: attempt to index a nil value",
		});
	});
});
