// The schema for the espionage section of the state: the player's spy capacity
// and every spy, as the Espionage screen's Operatives tab shows them. The core
// mod builds it in Scripts/State/SentientSystemsCore_StateEspionage.lua.

import { z } from "zod";

const CITY = z.object({ owner: z.number(), id: z.number(), name: z.string() });

const OPERATIVE = z.object({
	status: z.enum(["idle", "mission", "traveling", "captured"]).describe(
		"Idle and on a mission are on the map. Traveling is on the way to a city. Captured is held by another player.",
	),
	id: z.number().optional().describe("The spy's unit ID. Left out for a traveling or captured spy, which isn't a unit."),
	name: z.string().describe("In the game's language."),
	level: z.number().describe("1 to 4."),
	rank: z.string().describe("The rank's name, in the game's language."),
	city: CITY.optional().describe(
		"The city whose land the spy stands in, or, for a traveling spy, the city it is going to.",
	),
	operation: z.object({
		type: z.string().describe("Such as UNITOPERATION_SPY_GAIN_SOURCES."),
		name: z.string().describe("In the game's language."),
		turnsLeft: z.number(),
		totalTurns: z.number(),
	}).optional().describe("There on a mission only."),
	turnsLeft: z.number().optional().describe("The turns until a traveling spy arrives."),
	capturedBy: z.number().optional().describe("The player who holds a captured spy."),
	captive: z.number().optional().describe("The captured spy's index, which a deal to get it back uses."),
});

export const ESPIONAGE = z.object({
	capacity: z.number().describe("How many spies the player can have."),
	operatives: z.array(OPERATIVE).describe(
		"The idle spies, those on a mission, the captured ones, and then the traveling ones, as the tab lists them.",
	),
});
