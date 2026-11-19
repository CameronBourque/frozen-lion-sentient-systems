// The MCP tools that read the game: the state, the choices, placement, the
// trees, one city's trade routes, one great work's moves, and the
// Civilopedia. Each description is written for the model.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { readChoices } from "../choices/choices.js";
import { lookup, lookupPage, lookupSection, lookupSections } from "../lookup/lookup.js";
import { readPlacement } from "../placement/placement.js";
import { readCityRoutes } from "../state/city-routes.js";
import { readGreatWorkMoves } from "../state/great-work-moves.js";
import { readState } from "../state/state.js";
import { readCivicTree, readTechTree } from "../trees/research.js";
import type { TunerClient } from "../tuner/client.js";
import type { PlayerSource } from "./player.js";
import { readForPlayer, readFromGame } from "./results.js";

// What a server's tools need: the game, and the player they act for.
export interface ToolContext {
	client: TunerClient;
	player: PlayerSource;
}

const GET_STATE = `Read your empire and everything you can see, as JSON. Call it at the start of each turn and after actions that change the map.

It holds your cities, units, revealed tiles, rivals you can see, diplomacy, religion, great people, governors, trade, espionage, the scoreboard, and victory progress. Positions are x and y. Fog of war applies: rivals' units are only those you see now, and tiles are only those you have revealed.

blockers.list holds what stops the turn from ending, first one first. Each has choice, the key in get_choices that resolves it. blockers.units holds the IDs of units that still need orders.`;

const GET_CHOICES = `Read the legal options for every decision you can make now, as JSON.

It covers what each city can produce or buy, techs and civics, policies and governments, pantheon and religion beliefs, envoys, great people, governor titles, spy missions, trade routes, artifacts, dedications, emergencies, city fates, and the World Congress.

Pick from these options when you act. A key that a blocker in get_state names is the choice that resolves it. An option the game greys out has blocked, with the game's reasons.

production and purchases have an entry for each city, which makes them the largest part. Give cityID to list only that city in them, such as when you choose one city's production.`;

const GET_PLACEMENT = `Read where a city can place one district or wonder, as JSON. Call it before you build a district or wonder.

tiles are the city's own tiles where it can go now. purchaseTiles are tiles the city could buy for it. A district's tile has adjacency, its bonus by yield. Wonders and tiles with no bonus leave adjacency out.`;

const TREE_NOTES = `Each node has its status: researched, current, ready, or blocked. turns is the turns left at your current rate. In Tech and Civic Shuffle mode, a node you haven't revealed shows as ? and a number.

players lists you and each player you have met, with how many nodes they have researched.`;

const GET_TECH_TREE = `Read the whole tech tree as the tree screen shows it, as JSON. Use it to plan research further ahead than get_choices, which lists only the techs you can pick now.

${TREE_NOTES}`;

const GET_CIVIC_TREE = `Read the whole civic tree as the tree screen shows it, as JSON. Use it to plan civics further ahead than get_choices, which lists only the civics you can pick now.

${TREE_NOTES}`;

const GET_TRADE_ROUTES = `Read every trade route one of your cities could start, as JSON, as the Trade Overview's Available Routes tab lists them. Use it to plan where to build or send a trader. It needs no trader in the city.

Your own cities come first. Each destination has its distance, what the origin and the destination each receive, any religious pressure, and whether a city-state quest completes. get_choices lists the routes only for traders that stand idle in a city.`;

const GET_GREAT_WORK_MOVES = `Read the slots one of your great works can move to, as JSON, as the Great Works screen lights them up when you pick the work up. Call it before you move a great work.

from is the work's slot now. A move with swap trades places with the work already there. moves is empty when the work can't move, such as art that is still locked.`;

const SEARCH_CIVILOPEDIA = `Search the Civilopedia for a rule, unit, building, district, improvement, civilization, leader, belief, policy, or concept, as JSON. Returns up to 10 pages, best match first, each with its sectionID, pageID, title, and a snippet.

Open a result with read_civilopedia and its pageID. A game object's pageID is its type, such as UNIT_SETTLER, so you can also read a type from the state directly.`;

const READ_CIVILOPEDIA = `Open the Civilopedia by ID, as JSON. Use it for exact stats, costs, requirements, and rules instead of guessing.

- pageID: returns that page's text, as the Civilopedia shows it. A game object's pageID is its type, such as UNIT_SETTLER or DISTRICT_CAMPUS. Add sectionID only when a pageID is in more than one section, such as INTRO.
- sectionID alone: lists that section's pages by group.
- Neither: lists the sections.`;

export function registerStateTools(server: McpServer, { client, player }: ToolContext): void {
	server.registerTool("get_state", { description: GET_STATE }, () => readForPlayer(client, player, (playerID) => readState(client, playerID)));
	server.registerTool("get_choices", {
		description: GET_CHOICES,
		inputSchema: z.object({
			cityID: z.int().optional().describe("One of your cities' id, from get_state. Leave it out for every city."),
		}),
	}, ({ cityID }) => readForPlayer(client, player, (playerID) => readChoices(client, playerID, cityID)));
	server.registerTool("get_placement", {
		description: GET_PLACEMENT,
		inputSchema: z.object({
			cityID: z.int().describe("The city's id, from get_state."),
			type: z.string().describe("The district or wonder, such as DISTRICT_CAMPUS or BUILDING_STONEHENGE."),
		}),
	}, ({ cityID, type }) => readForPlayer(client, player, (playerID) => readPlacement(client, playerID, cityID, type)));
	server.registerTool("get_tech_tree", { description: GET_TECH_TREE }, () => readForPlayer(client, player, (playerID) => readTechTree(client, playerID)));
	server.registerTool("get_civic_tree", { description: GET_CIVIC_TREE }, () => readForPlayer(client, player, (playerID) => readCivicTree(client, playerID)));
	server.registerTool("get_trade_routes", {
		description: GET_TRADE_ROUTES,
		inputSchema: z.object({ cityID: z.int().describe("The id of one of your cities, from get_state.") }),
	}, ({ cityID }) => readForPlayer(client, player, (playerID) => readCityRoutes(client, playerID, cityID)));
	server.registerTool("get_great_work_moves", {
		description: GET_GREAT_WORK_MOVES,
		inputSchema: z.object({ workIndex: z.int().describe("The work's index, from greatWorks.slots[].work.index in get_state.") }),
	}, ({ workIndex }) => readForPlayer(client, player, (playerID) => readGreatWorkMoves(client, playerID, workIndex)));
	server.registerTool("search_civilopedia", {
		description: SEARCH_CIVILOPEDIA,
		inputSchema: z.object({
			query: z.string().min(1).describe("Words to find, such as campus adjacency or Gilgamesh."),
		}),
	}, ({ query }) => readFromGame(client, () => lookup(client, query)));
	server.registerTool("read_civilopedia", {
		description: READ_CIVILOPEDIA,
		inputSchema: z.object({
			pageID: z.string().min(1).optional().describe("The page to open, such as UNIT_SETTLER."),
			sectionID: z.string().min(1).optional().describe("The section, such as UNITS or CONCEPTS."),
		}),
	}, ({ pageID, sectionID }) => readFromGame(client, () => readCivilopedia(client, pageID, sectionID)));
}

// A page with an optional section, a section's pages, or the sections.
function readCivilopedia(client: TunerClient, pageID?: string, sectionID?: string): ReturnType<typeof lookupPage | typeof lookupSection | typeof lookupSections> {
	if (pageID !== undefined) {
		return lookupPage(client, pageID, sectionID);
	}

	return sectionID === undefined ? lookupSections(client) : lookupSection(client, sectionID);
}
