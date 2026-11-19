// Reads where one of the player's great works can move, as the Great Works
// screen lights up the slots for a picked-up work, through the stash. The core
// mod builds it in SentientSystemsCore_StateGreatWorks.lua.

import { z } from "zod";
import { GREAT_WORK_SLOT_REF } from "../schemas.js";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

const NAMED_WORK = z.object({
	index: z.number().describe("The game's index of the work."),
	name: z.string().describe("In the game's language."),
});

// Not strict, so a field from a newer core mod is dropped.
export const GREAT_WORK_MOVES = z.object({
	work: NAMED_WORK,
	from: GREAT_WORK_SLOT_REF.describe("The slot the work is in."),
	moves: z.array(GREAT_WORK_SLOT_REF.extend({
		swap: NAMED_WORK.optional().describe("The work already in the slot, which trades places with this one. Left out for an empty slot."),
	})).describe("The slots the work can move to. Empty when the work can't move, such as art that is locked."),
});

export type GreatWorkMoves = z.infer<typeof GREAT_WORK_MOVES>;

export function readGreatWorkMoves(client: TunerClient, playerID: number, workIndex: number): Promise<StashResult<GreatWorkMoves>> {
	return readStash(client, `SentientSystems_GetGreatWorkMoves(${playerID}, ${workIndex})`, GREAT_WORK_MOVES, "great work moves");
}
