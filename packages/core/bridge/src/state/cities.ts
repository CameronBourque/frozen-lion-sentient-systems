// The schema for the cities section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateCities.lua.

import { z } from "zod";
import { POSITION, YIELDS } from "../schemas.js";
import { HEALTH } from "./units.js";

// A city's defense, as its banner shows it. The rivals section uses it too.
export const DEFENSE = z.object({
	strength: z.number().describe("Rounded to a whole number, as the banner rounds it."),
	garrison: HEALTH,
	walls: HEALTH.optional().describe("Left out for a city with none."),
});

// A city's religion, as its banner shows it. The rivals section uses it too.
export const CITY_RELIGION = z.object({
	majority: z.string().optional().describe("Such as RELIGION_BUDDHISM. Left out while no religion has the most followers."),
	outwardPressure: z.number().describe(
		"The pressure the city exerts on other cities each turn, for its majority religion, rounded as the banner rounds it. 0 while it has no majority.",
	),
	converting: z.object({
		type: z.string().describe("The religion the city will convert to."),
		turns: z.number().describe("The turns until it converts, as the banner shows them."),
	}).optional().describe("Left out while the city isn't about to change its religion."),
	present: z.array(z.object({
		type: z.string().describe("RELIGION_PANTHEON for the citizens with no religion."),
		followers: z.number(),
		pressure: z.number().optional().describe("The pressure on the city each turn, rounded as the banner rounds it. Left out for the pantheon."),
		totalPressure: z.number().optional().describe("The pressure the city has received in all, rounded, as the banner's tooltip shows it. Left out for the pantheon."),
	})).describe("Every religion the city holds, with the followers of each, in the game's order."),
});

// A line of the Power tab: the text the game gives the source, and its power.
const POWER_LINE = z.object({ name: z.string().describe("The game's text, such as Factory."), power: z.number() });

export const CITY = z.object({
	id: z.number(),
	name: z.string().describe("In the game's language."),
	...POSITION.shape,
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
		...POSITION.shape,
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
	power: z.object({
		status: z.enum(["none", "powered", "unpowered"]).describe(
			"None when no building needs power, unpowered when the city is not fully powered, as the Power tab shows it. An unpowered city's buildings with a power load are less effective.",
		),
		usable: z.number().describe("The power the city can use, the free and temporary power together, or the required power while a project powers it."),
		required: z.number().describe("The power its buildings and projects need."),
		sources: z.array(POWER_LINE).describe("What gives the city power: the free and the temporary sources, such as Solar."),
		requiredBy: z.array(POWER_LINE).describe("What needs power, such as Factory."),
		generated: z.array(POWER_LINE).describe("The power the city generates for others."),
	}).optional().describe("The Power tab of the city panel. Left out without Gathering Storm."),
	production: z.object({
		type: z.string().optional().describe("Such as UNIT_SLINGER."),
		turnsLeft: z.number(),
	}).optional().describe("Left out when the city produces nothing."),
	religion: CITY_RELIGION,
	yields: YIELDS.required().describe("Per turn, each rounded down to one decimal place, as the city panel shows them."),
});
