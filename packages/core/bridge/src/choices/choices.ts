// Reads one player's choices from the core mod: the legal options for each discrete choice. The
// core mod builds them as JSON in a call of its own, so the agent reads them only when it decides,
// and the bridge reads them through the stash, in stash.ts. docs/design/core/in-game-lua.md has the
// format. Each choice's schema has its own file in this folder, as each choice of the core mod's
// Lua does.

import { z } from "zod";
import { readStash } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";
import { CAPTURED_CITIES_CHOICE } from "./captured-cities.js";
import { ENVOY_CHOICE } from "./envoys.js";
import { GREAT_PEOPLE_CHOICE } from "./great-people.js";
import { GOVERNMENT, GOVERNMENTS, POLICIES } from "./government.js";
import { PRODUCTION_CITY } from "./production.js";
import { PURCHASE_CITY } from "./purchases.js";
import { PANTHEON, RELIGION_CHOICE } from "./religion.js";
import { RESEARCH_OPTION } from "./research.js";

// Not strict, so a choice from a newer core mod is dropped instead of failing all the choices.
const CHOICES = z.object({
	production: z.array(PRODUCTION_CITY),
	purchases: z.array(PURCHASE_CITY),
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
});

export type Choices = z.infer<typeof CHOICES>;

export type ChoicesResult =
	| { ok: true; choices: Choices; bytes: number }
	| { ok: false; error: string };

// Reads the choices of the player with ID playerID. Every failure comes back as an error that says
// what went wrong, instead of an exception.
export async function readChoices(client: TunerClient, playerID: number): Promise<ChoicesResult> {
	const result = await readStash(client, `SentientSystems_GetChoices(${playerID})`, CHOICES, "choices");

	return result.ok ? { ok: true, choices: result.value, bytes: result.bytes } : result;
}
