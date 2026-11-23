// Tests for mcp/action.ts and the action tools: each tool sends its call for
// the server's player, through an in-process client and the fake game. A tool
// gets the ok only when its exact call is answered.

import type { Client } from "@modelcontextprotocol/client";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { Logger } from "../../src/log.js";
import { REASON_MAX_LENGTH, TOOK_REQUEST } from "../../src/mcp/action.js";
import { NOT_CONNECTED } from "../../src/mcp/results.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { type FakeGame, startGame } from "../tuner/fake-game.js";
import { PLAYER_3, answerStash, callTool, connectTools } from "./tools.js";

const OK = { ok: true };
const REASON = "Testing the tool.";
const DONE = { text: TOOK_REQUEST, isError: false };

let game: FakeGame;
let client: TunerClient;
let mcp: Client;

beforeEach(async () => {
	({ game, client } = await startGame());
	mcp = await connectTools(client);
});

afterEach(() => {
	vi.restoreAllMocks();
});

describe("registerAction", () => {
	test("returns that the game took the request", async () => {
		answerStash(game, { "SentientSystems_MoveUnit(3, 7, 10, 12)": OK });

		expect(await callTool(mcp, "move_unit", { reason: REASON, unitID: 7, x: 10, y: 12 })).toEqual(DONE);
	});

	test("returns a failed action's reason as an error result", async () => {
		answerStash(game, { "SentientSystems_MoveUnit(3, 7, 10, 12)": { ok: false, reason: "The unit has no moves left." } });

		expect(await callTool(mcp, "move_unit", { reason: REASON, unitID: 7, x: 10, y: 12 })).toEqual({ text: "The unit has no moves left.", isError: true });
	});

	test("answers at once when the bridge isn't connected to the game", async () => {
		const offline = await connectTools({ isConnected: false } as TunerClient);

		expect(await callTool(offline, "end_turn", { reason: REASON })).toEqual({ text: NOT_CONNECTED, isError: true });
	});
});

describe("the reason", () => {
	test("every action tool requires it, first in its schema", async () => {
		const { tools } = await mcp.listTools();
		// The memory tools change no game, so they aren't actions.
		const memory = ["update_plan", "add_journal_entry", "record_decision", "record_result"];
		const actions = tools.filter((tool) => !tool.name.startsWith("get_") && !tool.name.endsWith("_civilopedia") && !memory.includes(tool.name));

		expect(actions.length).toBeGreaterThan(30);
		expect(actions.every((tool) => tool.inputSchema.required?.includes("reason") === true && Object.keys(tool.inputSchema.properties ?? {})[0] === "reason")).toBe(true);
	});

	test("a call without it, or with one over the cap, fails and sends nothing", async () => {
		expect(await callTool(mcp, "end_turn")).toMatchObject({ isError: true });
		expect(await callTool(mcp, "end_turn", { reason: "x".repeat(REASON_MAX_LENGTH + 1) })).toMatchObject({ isError: true });
		expect(game.commands).toEqual([]);
	});

	test("an action logs its tool, reason, fields, and result at the decisions level", async () => {
		const log = vi.spyOn(console, "log").mockImplementation(() => {});
		const logger = new Logger("decisions", "");
		const logged = vi.spyOn(logger, "decision");

		answerStash(game, { "SentientSystems_MoveUnit(3, 7, 10, 12)": { ok: false, reason: "No moves left." } });
		await callTool(await connectTools(client, PLAYER_3, logger), "move_unit", { reason: REASON, unitID: 7, x: 10, y: 12 });

		expect(logged).toHaveBeenCalledWith("action", `move_unit: ${REASON}`, {
			tool: "move_unit", player: 3, reason: REASON, args: { unitID: 7, x: 10, y: 12 }, ok: false, failure: "No moves left.",
		});
		expect(log).toHaveBeenCalledWith(expect.stringContaining(`move_unit: ${REASON}`));
	});
});

describe("unit_action", () => {
	test("passes an order with no fields, a field, or a tile", async () => {
		answerStash(game, {
			"SentientSystems_UnitAction(3, 7, \"fortify\", nil, nil, nil)": OK,
			"SentientSystems_UnitAction(3, 7, \"promote\", nil, nil, \"PROMOTION_BATTLECRY\")": OK,
			"SentientSystems_UnitAction(3, 7, \"wmd_strike\", 4, 5, \"WMD_NUCLEAR_DEVICE\")": OK,
		});

		expect(await callTool(mcp, "unit_action", { reason: REASON, unitID: 7, action: "fortify" })).toEqual(DONE);
		expect(await callTool(mcp, "unit_action", { reason: REASON, unitID: 7, action: "promote", promotion: "PROMOTION_BATTLECRY" })).toEqual(DONE);
		expect(await callTool(mcp, "unit_action", { reason: REASON, unitID: 7, action: "wmd_strike", x: 4, y: 5, device: "WMD_NUCLEAR_DEVICE" })).toEqual(DONE);
	});

	test("refuses x without y, and sends nothing", async () => {
		expect(await callTool(mcp, "unit_action", { reason: REASON, unitID: 7, action: "attack", x: 4 })).toEqual({ text: "Give both x and y, or neither.", isError: true });
		expect(game.commands).toEqual([]);
	});

	test("refuses an order the action API doesn't have", async () => {
		expect(await callTool(mcp, "unit_action", { reason: REASON, unitID: 7, action: "dance" })).toMatchObject({ isError: true });
	});
});

describe("end_turn", () => {
	test("sends force only when it is given", async () => {
		answerStash(game, { "SentientSystems_EndTurn(3, false)": OK, "SentientSystems_EndTurn(3, true)": OK });

		expect(await callTool(mcp, "end_turn", { reason: REASON })).toEqual(DONE);
		expect(await callTool(mcp, "end_turn", { reason: REASON, force: true })).toEqual(DONE);
	});
});

describe("the city tools", () => {
	test("set_production replaces, or queues with queue, with or without a tile", async () => {
		answerStash(game, {
			"SentientSystems_SetProduction(3, 65536, \"UNIT_BUILDER\")": OK,
			"SentientSystems_SetProduction(3, 65536, \"DISTRICT_CAMPUS\", 4, 5)": OK,
			"SentientSystems_SetProduction(3, 65536, \"UNIT_BUILDER\", nil, nil, true)": OK,
		});

		expect(await callTool(mcp, "set_production", { reason: REASON, cityID: 65536, item: "UNIT_BUILDER" })).toEqual(DONE);
		expect(await callTool(mcp, "set_production", { reason: REASON, cityID: 65536, item: "DISTRICT_CAMPUS", x: 4, y: 5 })).toEqual(DONE);
		expect(await callTool(mcp, "set_production", { reason: REASON, cityID: 65536, item: "UNIT_BUILDER", queue: true })).toEqual(DONE);
	});

	test("set_production refuses y without x", async () => {
		expect(await callTool(mcp, "set_production", { reason: REASON, cityID: 65536, item: "DISTRICT_CAMPUS", y: 5 })).toEqual({ text: "Give both x and y, or neither.", isError: true });
	});

	test("purchase and purchase_tile pass the city, the item, the yield, and the tile", async () => {
		answerStash(game, {
			"SentientSystems_Purchase(3, 65536, \"UNIT_BUILDER\", \"faith\")": OK,
			"SentientSystems_PurchaseTile(3, 65536, 4, 5)": OK,
		});

		expect(await callTool(mcp, "purchase", { reason: REASON, cityID: 65536, item: "UNIT_BUILDER", yield: "faith" })).toEqual(DONE);
		expect(await callTool(mcp, "purchase_tile", { reason: REASON, cityID: 65536, x: 4, y: 5 })).toEqual(DONE);
	});
});

describe("the strike and city fate tools", () => {
	test("city_attack, silo_strike, and decide_city pass their fields", async () => {
		answerStash(game, {
			"SentientSystems_CityAttack(3, 65536, 4, 5)": OK,
			"SentientSystems_SiloStrike(3, 10, 11, 4, 5, \"WMD_NUCLEAR_DEVICE\")": OK,
			"SentientSystems_DecideCity(3, 131072, \"RAZE\")": OK,
		});

		expect(await callTool(mcp, "city_attack", { reason: REASON, cityID: 65536, x: 4, y: 5 })).toEqual(DONE);
		expect(await callTool(mcp, "silo_strike", { reason: REASON, siloX: 10, siloY: 11, x: 4, y: 5, device: "WMD_NUCLEAR_DEVICE" })).toEqual(DONE);
		expect(await callTool(mcp, "decide_city", { reason: REASON, cityID: 131072, directive: "RAZE" })).toEqual(DONE);
	});

	test("decide_city refuses a directive the game doesn't have", async () => {
		expect(await callTool(mcp, "decide_city", { reason: REASON, cityID: 131072, directive: "SELL" })).toMatchObject({ isError: true });
	});
});

describe("the research and government tools", () => {
	test("set_research and set_civic replace the queue, or add to it with queue", async () => {
		answerStash(game, {
			"SentientSystems_SetResearch(3, \"TECH_MINING\")": OK,
			"SentientSystems_SetResearch(3, \"TECH_MINING\", true)": OK,
			"SentientSystems_SetCivic(3, \"CIVIC_MYSTICISM\")": OK,
			"SentientSystems_SetCivic(3, \"CIVIC_MYSTICISM\", true)": OK,
		});

		expect(await callTool(mcp, "set_research", { reason: REASON, type: "TECH_MINING" })).toEqual(DONE);
		expect(await callTool(mcp, "set_research", { reason: REASON, type: "TECH_MINING", queue: true })).toEqual(DONE);
		expect(await callTool(mcp, "set_civic", { reason: REASON, type: "CIVIC_MYSTICISM" })).toEqual(DONE);
		expect(await callTool(mcp, "set_civic", { reason: REASON, type: "CIVIC_MYSTICISM", queue: true })).toEqual(DONE);
	});

	test("set_government passes the government", async () => {
		answerStash(game, { "SentientSystems_SetGovernment(3, \"GOVERNMENT_AUTOCRACY\")": OK });

		expect(await callTool(mcp, "set_government", { reason: REASON, government: "GOVERNMENT_AUTOCRACY" })).toEqual(DONE);
	});
});

describe("the policy and dedication tools", () => {
	test("set_policies lists every slot, with false for an empty one", async () => {
		answerStash(game, { "SentientSystems_SetPolicies(3, {[0] = \"POLICY_DISCIPLINE\", [1] = false})": OK });

		expect(await callTool(mcp, "set_policies", { reason: REASON, slots: ["POLICY_DISCIPLINE", null] })).toEqual(DONE);
	});

	test("unlock_policies and choose_dedications send their calls", async () => {
		answerStash(game, {
			"SentientSystems_UnlockPolicies(3)": OK,
			"SentientSystems_ChooseDedications(3, {\"COMMEMORATION_SCIENTIFIC\"})": OK,
		});

		expect(await callTool(mcp, "unlock_policies", { reason: REASON })).toEqual(DONE);
		expect(await callTool(mcp, "choose_dedications", { reason: REASON, dedications: ["COMMEMORATION_SCIENTIFIC"] })).toEqual(DONE);
	});
});

describe("the religion tools", () => {
	test("found_pantheon, found_religion with and without a name, and add_belief send their calls", async () => {
		answerStash(game, {
			"SentientSystems_FoundPantheon(3, \"BELIEF_RELIGIOUS_SETTLEMENTS\")": OK,
			"SentientSystems_FoundReligion(3, \"RELIGION_BUDDHISM\", {\"BELIEF_CHORAL_MUSIC\", \"BELIEF_TITHE\"})": OK,
			"SentientSystems_FoundReligion(3, \"RELIGION_CUSTOM\", {\"BELIEF_CHORAL_MUSIC\"}, \"Lionism\")": OK,
			"SentientSystems_AddBelief(3, \"BELIEF_TITHE\")": OK,
		});

		expect(await callTool(mcp, "found_pantheon", { reason: REASON, belief: "BELIEF_RELIGIOUS_SETTLEMENTS" })).toEqual(DONE);
		expect(await callTool(mcp, "found_religion", { reason: REASON, religion: "RELIGION_BUDDHISM", beliefs: ["BELIEF_CHORAL_MUSIC", "BELIEF_TITHE"] })).toEqual(DONE);
		expect(await callTool(mcp, "found_religion", { reason: REASON, religion: "RELIGION_CUSTOM", beliefs: ["BELIEF_CHORAL_MUSIC"], name: "Lionism" })).toEqual(DONE);
		expect(await callTool(mcp, "add_belief", { reason: REASON, belief: "BELIEF_TITHE" })).toEqual(DONE);
	});
});

describe("the governor tools", () => {
	test("appoint_governor, promote_governor, and assign_governor send their calls", async () => {
		answerStash(game, {
			"SentientSystems_AppointGovernor(3, \"GOVERNOR_THE_DEFENDER\")": OK,
			"SentientSystems_PromoteGovernor(3, \"GOVERNOR_THE_DEFENDER\", \"GOVERNOR_PROMOTION_EMBRASURE\")": OK,
			"SentientSystems_AssignGovernor(3, \"GOVERNOR_THE_DEFENDER\", 12, 65536)": OK,
		});

		expect(await callTool(mcp, "appoint_governor", { reason: REASON, governor: "GOVERNOR_THE_DEFENDER" })).toEqual(DONE);
		expect(await callTool(mcp, "promote_governor", { reason: REASON, governor: "GOVERNOR_THE_DEFENDER", promotion: "GOVERNOR_PROMOTION_EMBRASURE" })).toEqual(DONE);
		expect(await callTool(mcp, "assign_governor", { reason: REASON, governor: "GOVERNOR_THE_DEFENDER", owner: 12, cityID: 65536 })).toEqual(DONE);
	});
});

describe("the great people and great work tools", () => {
	const ARYABHATA = "GREAT_PERSON_INDIVIDUAL_ARYABHATA";

	test("recruit_great_person recruits by default, and passes or patronizes", async () => {
		answerStash(game, {
			[`SentientSystems_RecruitGreatPerson(3, "${ARYABHATA}")`]: OK,
			[`SentientSystems_PassGreatPerson(3, "${ARYABHATA}")`]: OK,
			[`SentientSystems_PatronizeGreatPerson(3, "${ARYABHATA}", "faith")`]: OK,
		});

		expect(await callTool(mcp, "recruit_great_person", { reason: REASON, greatPerson: ARYABHATA })).toEqual(DONE);
		expect(await callTool(mcp, "recruit_great_person", { reason: REASON, greatPerson: ARYABHATA, action: "pass" })).toEqual(DONE);
		expect(await callTool(mcp, "recruit_great_person", { reason: REASON, greatPerson: ARYABHATA, action: "patronize", yield: "faith" })).toEqual(DONE);
	});

	test("recruit_great_person refuses patronize without a yield", async () => {
		expect(await callTool(mcp, "recruit_great_person", { reason: REASON, greatPerson: ARYABHATA, action: "patronize" })).toEqual({ text: "Give patronize a yield, gold or faith.", isError: true });
	});

	test("move_great_work and choose_artifact send their calls", async () => {
		answerStash(game, {
			"SentientSystems_MoveGreatWork(3, 7, 65536, \"BUILDING_MUSEUM_ART\", 2)": OK,
			"SentientSystems_ChooseArtifact(3, 5)": OK,
		});

		expect(await callTool(mcp, "move_great_work", { reason: REASON, workIndex: 7, cityID: 65536, building: "BUILDING_MUSEUM_ART", slot: 2 })).toEqual(DONE);
		expect(await callTool(mcp, "choose_artifact", { reason: REASON, player: 5 })).toEqual(DONE);
	});
});

describe("the trade route and envoy tools", () => {
	test("start_trade_route and send_envoys send their calls, with 1 envoy by default", async () => {
		answerStash(game, {
			"SentientSystems_TradeRoute(3, 7, 12, 65536)": OK,
			"SentientSystems_SendEnvoys(3, 20, 1)": OK,
			"SentientSystems_SendEnvoys(3, 20, 2)": OK,
		});

		expect(await callTool(mcp, "start_trade_route", { reason: REASON, unitID: 7, owner: 12, cityID: 65536 })).toEqual(DONE);
		expect(await callTool(mcp, "send_envoys", { reason: REASON, cityState: 20 })).toEqual(DONE);
		expect(await callTool(mcp, "send_envoys", { reason: REASON, cityState: 20, count: 2 })).toEqual(DONE);
	});
});

describe("the espionage tools", () => {
	test("spy_mission with and without a district, spy_travel, and choose_escape_route send their calls", async () => {
		answerStash(game, {
			"SentientSystems_SpyMission(3, 7, \"UNITOPERATION_SPY_SIPHON_FUNDS\", nil)": OK,
			"SentientSystems_SpyMission(3, 7, \"UNITOPERATION_SPY_COUNTERSPY\", \"DISTRICT_CAMPUS\")": OK,
			"SentientSystems_SpyTravel(3, 7, 12, 65536)": OK,
			"SentientSystems_ChooseEscapeRoute(3, \"DISTRICT_HARBOR\")": OK,
		});

		expect(await callTool(mcp, "spy_mission", { reason: REASON, unitID: 7, mission: "UNITOPERATION_SPY_SIPHON_FUNDS" })).toEqual(DONE);
		expect(await callTool(mcp, "spy_mission", { reason: REASON, unitID: 7, mission: "UNITOPERATION_SPY_COUNTERSPY", district: "DISTRICT_CAMPUS" })).toEqual(DONE);
		expect(await callTool(mcp, "spy_travel", { reason: REASON, unitID: 7, owner: 12, cityID: 65536 })).toEqual(DONE);
		expect(await callTool(mcp, "choose_escape_route", { reason: REASON, route: "DISTRICT_HARBOR" })).toEqual(DONE);
	});
});

describe("the World Congress tools", () => {
	test("vote_in_congress sends a resolution vote by its option, and a proposal vote with against", async () => {
		answerStash(game, {
			"SentientSystems_VoteInCongress(3, {{ type = \"RESOLUTION_LUXURY_POLICY\", target = 1, votes = 2, option = \"B\" }, { type = \"WC_EMERGENCY_BACKSTAB\", target = 5, votes = 1, against = true }})": OK,
		});

		expect(await callTool(mcp, "vote_in_congress", { reason: REASON, votes: [
			{ type: "RESOLUTION_LUXURY_POLICY", option: "B", target: 1, votes: 2 },
			{ type: "WC_EMERGENCY_BACKSTAB", target: 5, votes: 1, against: true },
		] })).toEqual(DONE);
	});

	test("propose_in_congress sends the proposals, or an empty list to look", async () => {
		answerStash(game, {
			"SentientSystems_ProposeInCongress(3, {{ type = \"WC_EMERGENCY_BACKSTAB\", target = 5 }})": OK,
			"SentientSystems_ProposeInCongress(3, {})": OK,
		});

		expect(await callTool(mcp, "propose_in_congress", { reason: REASON, proposals: [{ type: "WC_EMERGENCY_BACKSTAB", target: 5 }] })).toEqual(DONE);
		expect(await callTool(mcp, "propose_in_congress", { reason: REASON, proposals: [] })).toEqual(DONE);
	});
});

describe("the diplomacy tools", () => {
	test("respond_to_deal, respond_to_session, and declare_war send their calls", async () => {
		answerStash(game, {
			"SentientSystems_RespondToDeal(3, 5, true)": OK,
			"SentientSystems_RespondToSession(3, 5, \"CHOICE_POSITIVE\")": OK,
			"SentientSystems_DeclareWar(3, 5)": OK,
		});

		expect(await callTool(mcp, "respond_to_deal", { reason: REASON, player: 5, accept: true })).toEqual(DONE);
		expect(await callTool(mcp, "respond_to_session", { reason: REASON, player: 5, option: "CHOICE_POSITIVE" })).toEqual(DONE);
		expect(await callTool(mcp, "declare_war", { reason: REASON, player: 5 })).toEqual(DONE);
	});

	test("propose_peace proposes, then returns ok once the war has ended", async () => {
		answerStash(game, { "SentientSystems_ProposePeace(3, 5)": OK, "SentientSystems_GetPeaceResult(3, 5)": OK });

		expect(await callTool(mcp, "propose_peace", { reason: REASON, player: 5 })).toEqual(DONE);
	});
});
