// The schema for the spy missions choice: for each spy ready to move, the
// cities it can travel to and the missions it can start where it stands, as
// the espionage chooser lists them. All text is in the game's language.

import { z } from "zod";
import { CITY_REF } from "../schemas.js";

const MISSION = z.object({
	type: z.string().describe("The operation, such as UNITOPERATION_SPY_SIPHON_FUNDS."),
	name: z.string(),
	district: z.string().describe("The district it targets, such as DISTRICT_COMMERCIAL_HUB. A mission with no district targets the city center."),
	districtName: z.string(),
	details: z.string().describe("The text under the mission's name, such as what it would yield."),
	turns: z.number().optional().describe("How long the mission takes. A counterspy mission has no time."),
	chances: z.object({
		success: z.number().describe("The whole percent."),
		failure: z.number().optional(),
		captured: z.number().optional().describe("The chance that the spy is captured or killed."),
	}).optional().describe("As the mission briefing shows them. Left out when the game gives none."),
	warning: z.string().optional().describe("That the target will learn who did it. Left out for a city-state or a sure success."),
	disabled: z.array(z.string()).optional().describe("The game's reasons, when it lists the mission as one the spy can't start."),
});

export const SPY_MISSIONS_CHOICE = z.array(z.object({
	spy: z.number().describe("The spy's unit ID."),
	name: z.string(),
	city: CITY_REF.optional().describe("The city it stands in. Left out when it stands in none."),
	missions: z.array(MISSION).optional().describe(
		"What it can start in that city: counterspy missions in a city of the player's, and the game's offensive missions in another's.",
	),
	destinations: z.array(CITY_REF.extend({
		capital: z.boolean().optional().describe("Only for a major civilization's capital."),
		turns: z.number().describe("The turns to get there and settle in."),
		travel: z.number(),
		establish: z.number(),
		districts: z.array(z.string()).describe("The complete districts, wonders left out, as the chooser's icons."),
	})).optional().describe("The cities it can travel to, in the chooser's order. Left out when the game won't send it anywhere."),
})).optional().describe("Left out when no spy is awake and ready to move. A spy on a mission or on its way isn't.");
