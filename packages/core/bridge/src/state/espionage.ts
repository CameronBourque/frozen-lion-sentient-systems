// The schema for the espionage section of the state: the player's spy capacity
// and every spy, as the Espionage screen's Operatives tab shows them. The core
// mod builds it in Scripts/State/SentientSystemsCore_StateEspionage.lua.

import { z } from "zod";
import { CITY_REF } from "../schemas.js";

const OPERATIVE = z.object({
	status: z.enum(["idle", "mission", "traveling", "captured"]).describe(
		"Idle and on a mission are on the map. Traveling is on the way to a city. Captured is held by another player.",
	),
	id: z.number().optional().describe("The spy's unit ID. Left out for a traveling or captured spy, which isn't a unit."),
	name: z.string().describe("In the game's language."),
	level: z.number().describe("1 to 4."),
	rank: z.string().describe("The rank's name, in the game's language."),
	city: CITY_REF.optional().describe(
		"The city whose land the spy stands in, or, for a traveling spy, the city it is going to.",
	),
	operation: z.object({
		type: z.string().describe("Such as UNITOPERATION_SPY_GAIN_SOURCES."),
		name: z.string().describe("In the game's language."),
		turnsLeft: z.number(),
		totalTurns: z.number(),
		district: z.string().optional().describe("The district the spy works in, such as DISTRICT_CAMPUS. Left out with none."),
	}).optional().describe("There on a mission only."),
	turnsLeft: z.number().optional().describe("The turns until a traveling spy arrives."),
	capturedBy: z.number().optional().describe("The player who holds a captured spy."),
	captive: z.number().optional().describe("The captured spy's index, which a deal to get it back uses."),
});

const ACTIVITY = z.object({
	owner: z.number().describe("A player ID."),
	id: z.number(),
	districts: z.array(z.string()).describe("The finished districts, such as DISTRICT_CAMPUS, without wonders, in the game's order."),
	sourcesTurnsLeft: z.number().optional().describe("The turns a Gain Sources boost has left. Left out with none."),
});

const HISTORY = z.object({
	name: z.string().describe("The spy's name, in the game's language."),
	level: z.number().describe("The spy's level after the mission."),
	rank: z.string().describe("The rank's name for that level, in the game's language."),
	operation: z.object({ type: z.string().describe("Such as UNITOPERATION_SPY_SIPHON_FUNDS."), name: z.string() }),
	turnsAgo: z.number(),
	city: z.string().describe("The name of the city, in the game's language."),
	success: z.boolean().describe(
		"As the tab calls it: false when the spy was killed or captured, even if the mission was done.",
	),
	fate: z.enum(["escaped", "killed", "captured"]).optional().describe(
		"What became of a spy that was detected. Left out when it was never detected.",
	),
	loot: z.string().optional().describe("What the mission took, as the tab words it. Left out with none."),
	description: z.string().describe("The tab's sentence about the outcome, in the game's language."),
});

const CAPTIVE = z.object({
	name: z.string().describe("In the game's language."),
	owner: z.number().describe("The player whose spy it is."),
	level: z.number(),
	rank: z.string(),
	captive: z.number().describe("The spy's index, which a deal to trade it back uses."),
});

export const ESPIONAGE = z.object({
	capacity: z.number().describe("How many spies the player can have."),
	operatives: z.array(OPERATIVE).describe(
		"The idle spies, those on a mission, the captured ones, and then the traveling ones, as the tab lists them.",
	),
	history: z.array(HISTORY).describe("The Mission History tab: up to the last 10 missions, the newest first."),
	captives: z.array(CAPTIVE).describe("The Mission History tab's other players' spies that the player holds."),
	cities: z.array(ACTIVITY).describe(
		"The City Activity tab: the cities of other major players on tiles the player has revealed, as the cities section lists the player's own.",
	),
});
