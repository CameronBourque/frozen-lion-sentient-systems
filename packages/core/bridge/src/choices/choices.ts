// Reads one player's choices from the core mod, as JSON through the stash in
// stash.ts, in a call of its own. Each choice's schema has its own file in
// this folder, as each choice of the core mod's Lua does.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";
import { ARTIFACTS_CHOICE } from "./artifacts.js";
import { CITY_FATE_CHOICE } from "./city-fate.js";
import { DEDICATIONS_CHOICE } from "./dedications.js";
import { EMERGENCIES_CHOICE } from "./emergencies.js";
import { ENVOY_CHOICE } from "./envoys.js";
import { GREAT_PEOPLE_CHOICE } from "./great-people.js";
import { GOVERNMENT, GOVERNMENTS, POLICIES } from "./government.js";
import { GOVERNORS_CHOICE } from "./governors.js";
import { PRODUCTION_CITY } from "./production.js";
import { PURCHASE_CITY } from "./purchases.js";
import { PANTHEON, RELIGION_CHOICE } from "./religion.js";
import { RESEARCH_OPTION } from "./research.js";
import { SPIES_CHOICE } from "./spies.js";
import { SPY_MISSIONS_CHOICE } from "./spy-missions.js";
import { TRADE_ROUTES_CHOICE } from "./trade-routes.js";
import { WORLD_CONGRESS_CHOICE } from "./world-congress.js";

// Not strict, so a choice from a newer core mod is dropped instead of failing
// all the choices.
export const CHOICES = z.object({
	production: z.array(PRODUCTION_CITY).describe(
		"One entry for each of the player's cities, in the game's order.",
	),
	purchases: z.array(PURCHASE_CITY).describe(
		"One entry for each of the player's cities, in the game's order.",
	),
	techs: z.array(RESEARCH_OPTION),
	civics: z.array(RESEARCH_OPTION),
	government: GOVERNMENT,
	policies: POLICIES,
	governments: GOVERNMENTS,
	pantheon: PANTHEON,
	religion: RELIGION_CHOICE,
	envoys: ENVOY_CHOICE,
	greatPeople: GREAT_PEOPLE_CHOICE,
	cityFates: CITY_FATE_CHOICE,
	spies: SPIES_CHOICE,
	tradeRoutes: TRADE_ROUTES_CHOICE,
	spyMissions: SPY_MISSIONS_CHOICE,
	artifacts: ARTIFACTS_CHOICE,
	governors: GOVERNORS_CHOICE,
	dedications: DEDICATIONS_CHOICE,
	emergencies: EMERGENCIES_CHOICE,
	worldCongress: WORLD_CONGRESS_CHOICE,
});

export type Choices = z.infer<typeof CHOICES>;

export function readChoices(client: TunerClient, playerID: number): Promise<StashResult<Choices>> {
	return readStash(client, `SentientSystems_GetChoices(${playerID})`, CHOICES, "choices");
}
