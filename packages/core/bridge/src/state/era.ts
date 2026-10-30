// The schema for the era part of the player section of the state: the era, the player's era score and
// age, the scores for the next age, the turns until the next era, and the other players' ages, as the
// Era Progress panel shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StatePlayerEra.lua.

import { z } from "zod";

const AGE = z.enum(["dark", "normal", "golden", "heroic"]);

// Left out in a game without the Rise and Fall expansion, which adds ages. type is the era, such as
// ERA_RENAISSANCE, and name its name in the game's language. score is the player's era score and age
// the age they are in. scoreBreakdown is what the score is made of, the earlier eras as one entry,
// each with the game's text for the source. effects has citizenLoyalty, the loyalty pressure each of
// the player's citizens exerts in their city, and the active dedications, each with the text of its
// bonus for the age. civilizations lists the players the player has met with their ages, in the
// panel's order, and unmet counts the others, which the panel shows with no age.
// Until the final era, nextAge is the age the score earns for the next era, thresholds has the score
// the next normal and golden age need, with normal left out in the Dramatic Ages mode, and
// turnsUntilNext is the least and the most turns until the era ends, the same once its countdown has
// started. The final era has final, true, instead.
export const ERA = z.object({
	type: z.string(),
	name: z.string(),
	score: z.number(),
	age: AGE,
	scoreBreakdown: z.array(z.object({ source: z.string(), points: z.number() })),
	effects: z.object({
		citizenLoyalty: z.number(),
		dedications: z.array(z.object({ type: z.string(), text: z.string() })),
	}),
	civilizations: z.array(z.object({ player: z.number(), age: AGE })),
	unmet: z.number(),
	final: z.literal(true).optional(),
	nextAge: z.enum(["dark", "normal", "golden"]).optional(),
	thresholds: z.object({ normal: z.number().optional(), golden: z.number() }).optional(),
	turnsUntilNext: z.object({ min: z.number(), max: z.number() }).optional(),
}).optional();
