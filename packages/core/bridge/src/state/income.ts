// The schema for the income part of the player section of the state: what the player makes each
// turn and where it comes from, what the player pays, the upkeep of each kind of unit, and the gold
// deals, as the Yields tab of Reports shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StatePlayerIncome.lua.

import { z } from "zod";

// One yield per turn: total, and each source the game's tooltip for it names, left out while it is 0.
// The sources are read from the game's English tooltip text, so in another language they all sit in
// other. gold's total is the income before the upkeep, which the top bar takes off. The sources are
// the cities, deals, beliefs, envoys, suzerain for the city-states the player is Suzerain of,
// interest, nationalParks, founders, alliances, greatPeople, and other, which also holds what no
// line explains, when it is at least half a point.
const YIELD = z.object({
	total: z.number(),
	cities: z.number().optional(),
	deals: z.number().optional(),
	beliefs: z.number().optional(),
	envoys: z.number().optional(),
	suzerain: z.number().optional(),
	interest: z.number().optional(),
	nationalParks: z.number().optional(),
	founders: z.number().optional(),
	alliances: z.number().optional(),
	greatPeople: z.number().optional(),
	other: z.number().optional(),
});

export const INCOME = z.object({
	gold: YIELD,
	faith: YIELD,
	science: YIELD,
	culture: YIELD,
	// The gold the player pays each turn: total, as the top bar has it, cities for the upkeep of
	// districts and buildings that aren't pillaged, which the cities' upkeep adds up to, units, and deals. other is what those don't
	// cover, when it is at least half a point.
	expenses: z.object({
		total: z.number(),
		cities: z.number(),
		units: z.number(),
		deals: z.number(),
		other: z.number().optional(),
	}),
	// Each city's rows in the order of the report's city table: city, with owner and id, tourism, the
	// tourism of its tiles, which the city's yields in the state's cities don't hold, upkeep, the gold
	// its districts and buildings cost, and sources. A source has kind, name, yields, each of food,
	// production, gold, science, culture, and faith, left out while 0, and upkeep, the gold it costs.
	// A row that gives no yield and costs nothing is left out. The kinds are district, adjacency, the
	// district's adjacency bonuses, building, wonder, greatWork, route, tiles, the worked tiles,
	// amenities, and population. type is there for a district, building, wonder, or great work, such
	// as BUILDING_FACTORY, and city, with owner and id, for the destination of a route.
	cities: z.array(z.object({
		city: z.object({ owner: z.number(), id: z.number() }),
		tourism: z.number(),
		upkeep: z.number(),
		sources: z.array(z.object({
			kind: z.enum(["district", "adjacency", "building", "wonder", "greatWork", "route", "tiles", "amenities", "population"]),
			name: z.string(),
			type: z.string().optional(),
			city: z.object({ owner: z.number(), id: z.number() }).optional(),
			yields: z.object({
				food: z.number().optional(),
				production: z.number().optional(),
				gold: z.number().optional(),
				science: z.number().optional(),
				culture: z.number().optional(),
				faith: z.number().optional(),
			}).optional(),
			upkeep: z.number().optional(),
		})),
	})),
	// The units that cost gold, grouped by type and formation, in the order of type. formation is
	// CORPS or ARMY, left out for single units, and gold is the cost of the group, less the player's
	// discount for each unit.
	unitUpkeep: z.array(z.object({
		type: z.string(),
		formation: z.enum(["CORPS", "ARMY"]).optional(),
		name: z.string(),
		count: z.number(),
		gold: z.number(),
	})),
	// The gold deals, each with the other player's ID, the turns left, and the gold each turn, which is
	// negative for gold the player pays.
	deals: z.array(z.object({ player: z.number(), turnsLeft: z.number(), gold: z.number() })),
});
