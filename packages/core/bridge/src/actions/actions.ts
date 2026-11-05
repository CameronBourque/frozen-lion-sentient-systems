// Runs an action in the core mod and reads its result. The core mod builds the
// result in Scripts/Actions/SentientSystemsCore_Actions.lua.

import { z } from "zod";
import { readStash } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

export const ACTION_RESULT = z.discriminatedUnion("ok", [
	z.object({ ok: z.literal(true) }),
	z.object({
		ok: z.literal(false),
		reason: z.string().describe(
			"Why the action failed. It comes from the game's own check where it gives one, and from the core mod's own message otherwise.",
		),
	}),
]);

export type ActionResult = z.infer<typeof ACTION_RESULT>;

// Sends the Lua call for an action to the core mod's state and returns its
// result. A failure to reach the game, or a reply that isn't a result, comes
// back as a failed result with that error as the reason.
export async function sendAction(client: TunerClient, call: string): Promise<ActionResult> {
	const result = await readStash(client, call, ACTION_RESULT, "action result");

	return result.ok ? result.value : { ok: false, reason: result.error };
}
