// Reads one player's state from the core mod: what blocks their turn, their cities, units, revealed
// tiles, the rivals they can see, their religion, their envoys, the great people on offer, their
// governors, and the top bar's numbers. The core mod builds the state as JSON, and the bridge reads it
// through the stash, in stash.ts. docs/design/core/in-game-lua.md has the format.
// Each section's schema has its own file in this folder, as each section of the core mod's Lua does.

import { z } from "zod";
import { readStash } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";
import { BLOCKERS } from "./blockers.js";
import { CITY } from "./cities.js";
import { DIPLOMACY } from "./diplomacy.js";
import { ENVOYS } from "./envoys.js";
import { GOVERNORS } from "./governors.js";
import { GREAT_PEOPLE } from "./great-people.js";
import { PLAYER } from "./player.js";
import { RELIGION } from "./religion.js";
import { RIVAL_CITY, RIVAL_UNIT } from "./rivals.js";
import { TILE } from "./tiles.js";
import { UNIT } from "./units.js";

// Not strict, so a field from a newer core mod is dropped instead of failing the whole state.
const STATE = z.object({
	blockers: BLOCKERS,
	cities: z.array(CITY),
	diplomacy: DIPLOMACY,
	units: z.array(UNIT),
	tiles: z.array(TILE),
	rivals: z.object({ cities: z.array(RIVAL_CITY), units: z.array(RIVAL_UNIT) }),
	religion: RELIGION,
	envoys: ENVOYS,
	greatPeople: GREAT_PEOPLE,
	governors: GOVERNORS,
	player: PLAYER,
});

export type State = z.infer<typeof STATE>;

export type StateResult =
	| { ok: true; state: State; bytes: number }
	| { ok: false; error: string };

// Reads the state of the player with ID playerID. Every failure comes back as an error that says what
// went wrong, instead of an exception.
export async function readState(client: TunerClient, playerID: number): Promise<StateResult> {
	const result = await readStash(client, `SentientSystems_GetState(${playerID})`, STATE, "state");

	return result.ok ? { ok: true, state: result.value, bytes: result.bytes } : result;
}
