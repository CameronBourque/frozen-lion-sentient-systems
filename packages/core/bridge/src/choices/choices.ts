// Reads one player's choices from the core mod: the legal options for each discrete choice. The
// core mod builds them as JSON in a call of its own, so the agent reads them only when it decides,
// and the bridge reads them through the stash, in stash.ts. Each choice's schema has its own file in
// this folder, as each choice of the core mod's Lua does, and holds the choice's shape.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";
import { ARTIFACTS_CHOICE } from "./artifacts.js";
import { CAPTURED_CITIES_CHOICE } from "./captured-cities.js";
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
import { WORLD_CONGRESS_CHOICE } from "./world-congress.js";

// Not strict, so a choice from a newer core mod is dropped instead of failing all the choices.
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
	capturedCities: CAPTURED_CITIES_CHOICE,
	spies: SPIES_CHOICE,
	artifacts: ARTIFACTS_CHOICE,
	governors: GOVERNORS_CHOICE,
	dedications: DEDICATIONS_CHOICE,
	emergencies: EMERGENCIES_CHOICE,
	worldCongress: WORLD_CONGRESS_CHOICE,
});

export type Choices = z.infer<typeof CHOICES>;

// Reads the choices of the player with ID playerID. Every failure comes back as an error that says
// what went wrong, instead of an exception.
export function readChoices(client: TunerClient, playerID: number): Promise<StashResult<Choices>> {
	return readStash(client, `SentientSystems_GetChoices(${playerID})`, CHOICES, "choices");
}
