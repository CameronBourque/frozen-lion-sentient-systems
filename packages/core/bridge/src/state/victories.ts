// The schema for the victories section of the state: how close each living major player is to each
// victory, in the order the Overall tab of World Rankings ranks them, with the numbers its icon
// tooltips show. The core mod builds it in Scripts/State/SentientSystemsCore_StateVictories.lua.
// Format: docs/findings/game-victories.md.

import { z } from "zod";

// A player that has been met has player and progress, from 0 to 1, and the keys of the victory's
// tooltip. One that has not been met has unmet and no ID. Both have the keys that the victory's own
// tab shows for every player.
const entry = <M extends z.ZodRawShape, E extends z.ZodRawShape>(met: M, every: E) =>
	z.union([
		z.object({ unmet: z.literal(true), ...every }),
		z.object({ player: z.number(), progress: z.number(), ...every, ...met }),
	]);

// The tasks of a stage of the science victory, in the Science tab's tooltip order: the Spaceport for
// the first stage, then for each project the tech it needs and the project. A stage is done when
// all its projects are.
const STAGE = z.object({
	progress: z.number(),
	done: z.boolean(),
	tasks: z.array(z.object({ kind: z.enum(["district", "tech", "project"]), type: z.string(), done: z.boolean() })),
});

// Each victory is left out when it is off or when no player can win it, and diplomatic is left out
// without Gathering Storm. Keys are left out when empty, such as the captured capitals of a player
// that has none.
export const VICTORIES = z.object({
	// lightYears is left out until the exoplanet expedition is launched, and without Gathering Storm.
	science: z.array(entry({
		techs: z.number(),
		sciencePerTurn: z.number(),
		stages: z.array(STAGE),
		lightYears: z.object({ current: z.number(), needed: z.number(), perTurn: z.number() }).optional(),
	}, {})).optional(),
	// touristsFromYou is left out for the player. dominance is who is culturally dominant over whom, and
	// dominating and dominatedBy count that for the player.
	culture: z.array(entry({
		tourismPerTurn: z.number(),
		culturePerTurn: z.number(),
		turnsToVictory: z.number().optional(),
		dominance: z.enum(["you", "them"]).optional(),
		dominating: z.number().optional(),
		dominatedBy: z.number().optional(),
	}, {
		domesticTourists: z.number(),
		visitingTourists: z.number(),
		requiredTourists: z.number(),
		touristsFromYou: z.number().optional(),
		tourismBreakdown: z.array(z.string()).optional(),
	})).optional(),
	// The domination keys are left out for a player with no capital. capturedCapitals names only the
	// owners that have been met, and capitalsCaptured counts them all.
	domination: z.array(entry({ military: z.number() }, {
		hasOriginalCapital: z.boolean().optional(),
		capitalsCaptured: z.number().optional(),
		capturedCapitals: z.array(z.number()).optional(),
	})).optional(),
	// The religion keys are left out for a player that founded none. convertedCivs names only the civs
	// that have been met, and civsConverted counts them all.
	religion: z.array(entry({ cities: z.number(), faithPerTurn: z.number() }, {
		religion: z.string().optional(),
		religionName: z.string().optional(),
		civsConverted: z.number().optional(),
		convertedCivs: z.array(z.number()).optional(),
	})).optional(),
	// required is the points that win it.
	diplomatic: z.array(entry({}, {
		points: z.number(),
		required: z.number(),
		breakdown: z.array(z.string()).optional(),
	})).optional(),
});
