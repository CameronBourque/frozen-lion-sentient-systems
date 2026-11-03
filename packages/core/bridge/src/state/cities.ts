// The schema for the cities section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateCities.lua.

import { z } from "zod";
import { HEALTH } from "./units.js";

// A city's defense, as its banner shows it. The rivals section uses it too.
export const DEFENSE = z.object({
	strength: z.number().describe("Rounded to a whole number, as the banner rounds it."),
	garrison: HEALTH,
	walls: HEALTH.optional().describe("Left out for a city with none."),
});

export const CITY = z.object({
	id: z.number(),
	name: z.string().describe("In the game's language."),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	amenities: z.object({
		have: z.number(),
		need: z.number(),
		mood: z.string().optional().describe("Such as HAPPINESS_CONTENT."),
		warWeariness: z.number().describe(
			"The amenities lost to war weariness, as the City Status tab of Reports shows them.",
		),
	}).describe("The city panel shows have minus need."),
	defense: DEFENSE,
	districts: z.array(z.object({
		type: z.string().describe("Wonders sit in DISTRICT_WONDER."),
		x: z.number(),
		y: z.number(),
		complete: z.boolean().describe("False for a district that is placed but not built yet."),
		pillaged: z.boolean(),
		buildings: z.array(z.object({ type: z.string(), pillaged: z.boolean() })).describe(
			"The built buildings.",
		),
	})),
	growth: z.object({
		foodSurplus: z.number().describe("Per turn, rounded down to one decimal place."),
		housing: z.number().describe("Rounded down to one decimal place."),
		rate: z.enum(["normal", "slowed", "halted", "accelerated"]).describe(
			"The growth rate status of the City Status tab of Reports: slowed at a housing growth modifier of 0.5 or less, halted at 0 or while the city is occupied, and accelerated when its amenities speed it up.",
		),
		turnsUntilGrowth: z.number().optional().describe("There while the city grows."),
		turnsUntilLoss: z.number().optional().describe(
			"There while the city starves. A city that neither grows nor starves has neither count.",
		),
	}),
	governor: z.object({
		type: z.string().describe("Such as GOVERNOR_THE_MERCHANT."),
		established: z.boolean().describe("Whether the governor has settled in."),
	}).optional().describe("Left out for none, and in a game without the Rise and Fall expansion."),
	loyalty: z.object({
		value: z.number().describe("Rounded to the nearest tenth, as the city panel shows it."),
		max: z.number(),
		perTurn: z.number().describe("Rounded to the nearest tenth, as the city panel shows it."),
	}).optional().describe("Left out in a game without the Rise and Fall expansion."),
	production: z.object({
		type: z.string().optional().describe("Such as UNIT_SLINGER."),
		turnsLeft: z.number(),
	}).optional().describe("Left out when the city produces nothing."),
	yields: z.object({
		food: z.number(),
		production: z.number(),
		gold: z.number(),
		science: z.number(),
		culture: z.number(),
		faith: z.number(),
	}).describe("Per turn, each rounded down to one decimal place, as the city panel shows them."),
});
