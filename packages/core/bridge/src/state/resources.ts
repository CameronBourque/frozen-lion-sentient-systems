// The schema for the resources part of the player section of the state, as the
// Resources tab of Reports shows it. The core mod builds it in
// Scripts/State/SentientSystemsCore_StatePlayerResources.lua.

import { z } from "zod";

const CITY = z.object({ owner: z.number(), id: z.number() });

const SOURCE = z.discriminatedUnion("kind", [
	z.object({
		kind: z.literal("city"),
		city: CITY,
		name: z.string(),
		amount: z.number(),
	}).describe("A city that owns the resource."),
	z.object({
		kind: z.literal("deal"),
		player: z.number().describe("The other player."),
		turnsLeft: z.number(),
		amount: z.number().describe("Negative when the player sends the resource."),
	}).describe("A resource traded."),
	z.object({
		kind: z.literal("suzerain"),
		player: z.number().describe("The city-state's player ID."),
		amount: z.number(),
	}).describe("A city-state's export, which the player gets as its suzerain."),
	z.object({
		kind: z.enum(["units", "power", "reserve", "cityStates", "other"]),
		amount: z.number().describe("Negative for what is used."),
	}).describe(
		"units and power are what they use each turn, reserve is what is reserved, and cityStates is what city-states send, all with Gathering Storm. other is the game's Gameplay Bonuses, the amount that no source explains.",
	),
]);

// Each resource the Resources tab lists, in the game's order. A resource with
// no sources and no stockpile is left out.
export const RESOURCES = z.array(z.object({
	type: z.string().describe("Such as RESOURCE_IRON."),
	name: z.string(),
	class: z.enum(["strategic", "luxury", "bonus"]),
	sources: z.array(SOURCE),
	cities: z.array(z.object({ city: CITY, amount: z.number() })).optional().describe(
		"The cities the game gives the resource to. Left out for none.",
	),
	total: z.number().optional().describe(
		"The sum of the sources. A strategic resource has perTurn in its place with Gathering Storm.",
	),
	perTurn: z.number().optional().describe("What the resource adds to the stockpile each turn."),
	stockpile: z.number().optional().describe("As the strip at the bottom of the screen shows it."),
	max: z.number().optional().describe("As the strip at the bottom of the screen shows it."),
}));
