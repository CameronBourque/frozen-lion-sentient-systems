// The schema for the victories section of the state: how close each living major player is to each
// victory, in the order the Overall tab of World Rankings ranks them, with the numbers its icon
// tooltips show. The core mod builds it in Scripts/State/SentientSystemsCore_StateVictories.lua.
// How each tab was checked: docs/findings/game-victories.md.

import { z } from "zod";

// A player that has been met has player and progress, and the keys of the victory's tooltip. One that
// has not been met has unmet and no ID. Both have the keys that the victory's own tab shows for every
// player.
const entry = <M extends z.ZodRawShape, E extends z.ZodRawShape>(met: M, every: E) =>
	z.union([
		z.object({ unmet: z.literal(true), ...every }),
		z.object({
			player: z.number(),
			progress: z.number().describe("From 0 to 1, rounded to the nearest thousandth."),
			...every,
			...met,
		}),
	]);

const STAGE = z.object({
	progress: z.number().describe("From 0 to 1."),
	done: z.boolean().describe("True when all its projects are."),
	tasks: z.array(z.object({
		kind: z.enum(["district", "tech", "project"]).describe(
			"district is the Spaceport, for the first stage only.",
		),
		type: z.string(),
		done: z.boolean(),
	})).describe(
		"In the Science tab's tooltip order: the Spaceport for the first stage, then for each project the tech it needs and the project.",
	),
});

// Each list has one entry for each player, ranked by progress and then the two numbers of the icon's
// tooltip, best first. Teams aren't grouped. Numbers other than progress are rounded to the nearest
// tenth.
export const VICTORIES = z.object({
	science: z.array(entry({
		techs: z.number(),
		sciencePerTurn: z.number(),
		stages: z.array(STAGE).describe(
			"As the Science tab's bars and tooltips show them: three in the base game and four with Gathering Storm.",
		),
		lightYears: z.object({ current: z.number(), needed: z.number(), perTurn: z.number() }).optional().describe(
			"With Gathering Storm, once the exoplanet expedition is launched. needed is the viewing player's.",
		),
	}, {})).optional(),
	culture: z.array(entry({
		tourismPerTurn: z.number(),
		culturePerTurn: z.number(),
		turnsToVictory: z.number().optional().describe("There when above 0."),
		dominance: z.enum(["you", "them"]).optional().describe("Who is culturally dominant over whom."),
		dominating: z.number().optional().describe("For the player: the number of players they dominate."),
		dominatedBy: z.number().optional().describe(
			"For the player: the number of players that are culturally dominant over them.",
		),
	}, {
		domesticTourists: z.number(),
		visitingTourists: z.number(),
		requiredTourists: z.number(),
		touristsFromYou: z.number().optional().describe("Left out for the player."),
		tourismBreakdown: z.array(z.string()).optional().describe("The lines of its tooltip without icons."),
	})).optional(),
	domination: z.array(entry({ military: z.number() }, {
		hasOriginalCapital: z.boolean().optional().describe("Left out, with the next two, for a player with no capital."),
		capitalsCaptured: z.number().optional().describe("Counts all the owners."),
		capturedCapitals: z.array(z.number()).optional().describe("The IDs of the owners they have met."),
	})).optional(),
	religion: z.array(entry({ cities: z.number().describe("Following their religion."), faithPerTurn: z.number() }, {
		religion: z.string().optional().describe("Its type. Left out, with the next three, for a player that founded none."),
		religionName: z.string().optional(),
		civsConverted: z.number().optional().describe("Counts all the civs."),
		convertedCivs: z.array(z.number()).optional().describe("The IDs of the civs they have met."),
	})).optional(),
	diplomatic: z.array(entry({}, {
		points: z.number(),
		required: z.number().describe("The points that win it."),
		breakdown: z.array(z.string()).optional().describe("The lines of its tooltip without icons."),
	})).optional().describe("Left out without Gathering Storm."),
}).describe(
	"Each victory is left out when it is off or when no player can win it. Keys are left out when empty, such as the captured capitals of a player that has none.",
);
