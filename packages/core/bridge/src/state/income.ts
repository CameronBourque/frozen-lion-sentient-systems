// The schema for the income part of the player section of the state, as the Yields tab of Reports
// shows it. The core mod builds it in
// Scripts/State/SentientSystemsCore_StatePlayerIncome.lua.

import { z } from "zod";

const CITY = z.object({ owner: z.number(), id: z.number() });

// One yield per turn. Each source is the one the game's tooltip for the yield names, and is left out
// while it is 0.
const YIELD = z.object({
	total: z.number().describe("Gold's total is the income before the upkeep, which the top bar takes off."),
	cities: z.number().optional(),
	deals: z.number().optional(),
	beliefs: z.number().optional(),
	envoys: z.number().optional(),
	suzerain: z.number().optional().describe("From the city-states the player is Suzerain of."),
	interest: z.number().optional(),
	nationalParks: z.number().optional(),
	founders: z.number().optional(),
	alliances: z.number().optional(),
	greatPeople: z.number().optional(),
	other: z.number().optional().describe(
		"The tooltip's Other line, which also holds what no line explains, when it is at least half a point.",
	),
}).describe(
	"The sources are matched to the game's English tooltip text, so in another language they all sit in other.",
);

export const INCOME = z.object({
	gold: YIELD,
	faith: YIELD,
	science: YIELD,
	culture: YIELD,
	expenses: z.object({
		total: z.number().describe("As the top bar has it."),
		cities: z.number().describe(
			"The upkeep of districts and buildings that aren't pillaged, which the cities' upkeep adds up to.",
		),
		units: z.number(),
		deals: z.number(),
		other: z.number().optional().describe("What the others don't cover, when it is at least half a point."),
	}).describe("The gold the player pays each turn."),
	cities: z.array(z.object({
		city: CITY,
		tourism: z.number().describe(
			"The tourism of the city's tiles, which the city's yields in the state's cities don't hold.",
		),
		upkeep: z.number().describe("The gold the city's districts and buildings cost."),
		sources: z.array(z.object({
			kind: z.enum(["district", "adjacency", "building", "wonder", "greatWork", "route", "tiles", "amenities", "population"]).describe(
				"adjacency is a district's adjacency bonuses, and tiles the worked tiles.",
			),
			name: z.string(),
			type: z.string().optional().describe(
				"There for a district, building, wonder, or great work, such as BUILDING_FACTORY.",
			),
			city: CITY.optional().describe("The destination of a route."),
			yields: z.object({
				food: z.number().optional(),
				production: z.number().optional(),
				gold: z.number().optional(),
				science: z.number().optional(),
				culture: z.number().optional(),
				faith: z.number().optional(),
			}).optional().describe("Each yield that isn't 0."),
			upkeep: z.number().optional().describe("The gold the source costs."),
		})).describe("The rows of the report's city table, in its order. A row with no yield and no upkeep is left out."),
	})),
	unitUpkeep: z.array(z.object({
		type: z.string(),
		formation: z.enum(["CORPS", "ARMY"]).optional().describe("Left out for single units."),
		name: z.string(),
		count: z.number(),
		gold: z.number().describe("The cost of the group, less the player's discount for each unit."),
	})).describe("The units that cost gold, grouped by type and formation, in the order of type."),
	deals: z.array(z.object({
		player: z.number().describe("The other player's ID."),
		turnsLeft: z.number(),
		gold: z.number().describe("Each turn. Negative for gold the player pays."),
	})).describe("The gold deals."),
});
