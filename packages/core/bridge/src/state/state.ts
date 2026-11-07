// Reads one player's state from the core mod, as JSON through the stash in
// stash.ts. Each section's schema has its own file in this folder, as each
// section of the core mod's Lua does.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";
import { BLOCKERS } from "./blockers.js";
import { CITY } from "./cities.js";
import { CONTINENT } from "./continents.js";
import { DIPLOMACY } from "./diplomacy.js";
import { ENVOYS } from "./envoys.js";
import { ESPIONAGE } from "./espionage.js";
import { GOVERNORS } from "./governors.js";
import { GREAT_PEOPLE } from "./great-people.js";
import { GREAT_WORKS } from "./great-works.js";
import { PLAYER } from "./player.js";
import { PROPOSALS } from "./proposals.js";
import { RELIGION } from "./religion.js";
import { RIVAL_CITY, RIVAL_UNIT } from "./rivals.js";
import { SCOREBOARD } from "./scoreboard.js";
import { TILE } from "./tiles.js";
import { TRADE } from "./trade.js";
import { UNIT } from "./units.js";
import { VICTORIES } from "./victories.js";

// Not strict, so a field from a newer core mod is dropped instead of failing
// the whole state.
export const STATE = z.object({
	blockers: BLOCKERS,
	cities: z.array(CITY),
	diplomacy: DIPLOMACY,
	units: z.array(UNIT).describe(
		"The player's units on the map. A unit at X -9999, or one that is dead or about to die, is left out.",
	),
	tiles: z.array(TILE).describe("The tiles the player has revealed, in plot index order."),
	continents: z.array(CONTINENT).describe("The continents with a tile the player has revealed, as the continents lens key lists them."),
	rivals: z.object({
		cities: z.array(RIVAL_CITY).describe("Other players' cities on tiles the player has revealed."),
		units: z.array(RIVAL_UNIT).describe("Other players' units that the player can see now."),
	}),
	proposals: PROPOSALS,
	religion: RELIGION,
	envoys: ENVOYS,
	espionage: ESPIONAGE,
	greatPeople: GREAT_PEOPLE,
	greatWorks: GREAT_WORKS,
	governors: GOVERNORS,
	player: PLAYER,
	trade: TRADE,
	scoreboard: SCOREBOARD,
	victories: VICTORIES,
});

export type State = z.infer<typeof STATE>;

export function readState(client: TunerClient, playerID: number): Promise<StashResult<State>> {
	return readStash(client, `SentientSystems_GetState(${playerID})`, STATE, "state");
}
