// The schema for the sessions section of the state: the leader screens other
// players have opened with the player, other than deals, as the leader screen
// shows them.

import { z } from "zod";

const OPTION = z.object({
	key: z.string().describe("Such as CHOICE_POSITIVE. CHOICE_EXIT is the goodbye."),
	text: z.string().optional().describe("The button's text."),
	disabled: z.string().optional().describe("Why the option can't be picked now. Left out when it can."),
});

export const SESSIONS = z.array(z.object({
	from: z.number(),
	statement: z.string().optional().describe("Such as FIRST_MEET. Left out when unknown."),
	subType: z.string().optional().describe("Such as NO_MANS for a meeting outside both borders. Left out for NONE."),
	text: z.string().optional().describe("What the leader says."),
	reason: z.string().optional().describe("The reason the leader screen shows under the text."),
	options: z.array(OPTION).optional().describe("In the leader screen's order. Left out when unknown."),
	unknown: z.literal(true).optional().describe(
		"The core mod didn't see the statement, as after the game loads, so only the goodbye is known to close it.",
	),
}));
