// Reads one player's state from the core mod: their cities, units, revealed tiles, and the rivals
// they can see. The core mod builds the state as JSON and keeps it in pieces, because the tuner
// gives no reply to a command whose output passes about 2 MiB. The bridge reads one piece per
// command and joins them. docs/design/core/in-game-lua.md has the format.

import { z } from "zod";
import { CORE_STATE } from "./connect.js";
import { type TunerClient, TunerLuaError, TunerMissingStateError, TunerTimeoutError } from "./tuner/client.js";

const HEALTH = z.object({ value: z.number(), max: z.number() });

const CITY = z.object({
	id: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	amenities: z.object({ have: z.number(), need: z.number(), mood: z.string().optional() }),
	districts: z.array(z.object({
		type: z.string(),
		x: z.number(),
		y: z.number(),
		complete: z.boolean(),
		pillaged: z.boolean(),
		buildings: z.array(z.object({ type: z.string(), pillaged: z.boolean() })),
	})),
	growth: z.object({
		foodSurplus: z.number(),
		housing: z.number(),
		turnsUntilGrowth: z.number().optional(),
		turnsUntilLoss: z.number().optional(),
	}),
	// Only in a game with the Rise and Fall expansion.
	loyalty: z.object({ value: z.number(), max: z.number(), perTurn: z.number() }).optional(),
	// Left out when the city produces nothing.
	production: z.object({ type: z.string().optional(), turnsLeft: z.number() }).optional(),
	yields: z.object({
		food: z.number(),
		production: z.number(),
		gold: z.number(),
		science: z.number(),
		culture: z.number(),
		faith: z.number(),
	}),
});

const UNIT = z.object({
	id: z.number(),
	type: z.string(),
	x: z.number(),
	y: z.number(),
	moves: z.object({ left: z.number(), max: z.number() }),
	health: HEALTH,
	// These three are left out for a unit with no experience.
	experience: z.object({ points: z.number(), nextLevel: z.number() }).optional(),
	promotions: z.array(z.string()).optional(),
	availablePromotions: z.array(z.string()).optional(),
});

const TILE = z.object({
	x: z.number(),
	y: z.number(),
	terrain: z.string(),
	feature: z.string().optional(),
	resource: z.string().optional(),
	owner: z.number().optional(),
	district: z.string().optional(),
	improvement: z.string().optional(),
	// The core mod sends these two only when they are true.
	improvementPillaged: z.literal(true).optional(),
	route: z.string().optional(),
	routePillaged: z.literal(true).optional(),
	visible: z.boolean(),
});

const RIVAL_CITY = z.object({
	owner: z.number(),
	id: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	capital: z.boolean(),
	defense: z.object({ strength: z.number(), garrison: HEALTH, walls: HEALTH.optional() }),
});

const RIVAL_UNIT = z.object({
	owner: z.number(),
	id: z.number(),
	type: z.string(),
	x: z.number(),
	y: z.number(),
	health: HEALTH,
});

// Not strict, so a field from a newer core mod is dropped instead of failing the whole state.
const STATE = z.object({
	cities: z.array(CITY),
	units: z.array(UNIT),
	tiles: z.array(TILE),
	rivals: z.object({ cities: z.array(RIVAL_CITY), units: z.array(RIVAL_UNIT) }),
});

export type State = z.infer<typeof STATE>;

export type StateResult =
	| { ok: true; state: State; bytes: number }
	| { ok: false; error: string };

// Reads the state of the player with ID playerID. Every failure, from the tuner, the game, the JSON,
// or the schema, comes back as an error that says what went wrong, instead of an exception.
export async function readState(client: TunerClient, playerID: number): Promise<StateResult> {
	let json: string;

	try {
		json = await readPieces(client, playerID);
	} catch (error) {
		return { ok: false, error: explainFailure(error) };
	}

	let value: unknown;

	try {
		value = JSON.parse(json);
	} catch (error) {
		return { ok: false, error: `The core mod's state isn't valid JSON: ${(error as Error).message}` };
	}

	const parsed = STATE.safeParse(value);

	if (!parsed.success) {
		return { ok: false, error: `The core mod's state doesn't match the schema: ${parsed.error.issues.map(describeIssue).join("; ")}` };
	}

	return { ok: true, state: parsed.data, bytes: Buffer.byteLength(json) };
}

// Asks the core mod to build and keep the state, then reads each piece with its own command and
// joins them. The core mod escapes each newline in the JSON, so the pieces join with nothing between.
async function readPieces(client: TunerClient, playerID: number): Promise<string> {
	const { lines } = await client.run(CORE_STATE, `SentientSystems_Stash(SentientSystems_GetState(${playerID}))`);
	const count = Number(lines.at(-1));

	if (lines.length !== 1 || !Number.isInteger(count) || count < 1) {
		throw new Error(`SentientSystems_Stash printed ${JSON.stringify(lines)}, not a piece count`);
	}

	const pieces: string[] = [];

	for (let piece = 1; piece <= count; piece++) {
		const result = await client.run(CORE_STATE, `SentientSystems_PrintPiece(${piece})`);

		pieces.push(result.lines.join(""));
	}

	return pieces.join("");
}

// The text for one schema issue, with the field's path in front, such as "cities.0.name: Invalid input".
function describeIssue(issue: z.core.$ZodIssue): string {
	return `${issue.path.join(".") || "the state"}: ${issue.message}`;
}

// The error for a failed read, with what the user can do about it.
function explainFailure(error: unknown): string {
	if (error instanceof TunerMissingStateError) {
		return `The core mod's state ${CORE_STATE} isn't loaded. Turn on Sentient Systems Core in Additional Content, then load a game`;
	}

	if (error instanceof TunerTimeoutError) {
		return "The game didn't answer the state request in time, maybe because a game is loading";
	}

	if (error instanceof TunerLuaError) {
		return `The core mod failed to build the state: ${error.message.split("\n")[0]}`;
	}

	return `Reading the state failed: ${error instanceof Error ? error.message : String(error)}`;
}
