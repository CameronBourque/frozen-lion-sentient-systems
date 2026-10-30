// The schema for the victories section of the state: how close each living major player is to each
// victory, in the order the Overall tab of World Rankings ranks them, with the numbers its icon
// tooltips show. The core mod builds it in Scripts/State/SentientSystemsCore_StateVictories.lua.

import { z } from "zod";

// A player the player hasn't met, which the tab shows only by its place.
const UNMET = z.object({ unmet: z.literal(true) });

// The player and each player they have met. progress is from 0 to 1.
const entry = <T extends z.ZodRawShape>(shape: T) =>
	z.union([UNMET, z.object({ player: z.number(), progress: z.number(), ...shape })]);

// The tasks of a stage of the science victory, in the Science tab's tooltip order: the Spaceport for
// the first stage, then for each project the tech it needs and the project. A stage is done when
// all its projects are.
const STAGE = z.object({
	progress: z.number(),
	done: z.boolean(),
	tasks: z.array(z.object({ kind: z.enum(["district", "tech", "project"]), type: z.string(), done: z.boolean() })),
});

// Each victory is left out when it is off or when no player can win it, and diplomatic is left out
// without Gathering Storm. required is the points that win it.
export const VICTORIES = z.object({
	// lightYears is left out until the exoplanet expedition is launched, and without Gathering Storm.
	science: z.array(entry({
		techs: z.number(),
		sciencePerTurn: z.number(),
		stages: z.array(STAGE),
		lightYears: z.object({ current: z.number(), needed: z.number(), perTurn: z.number() }).optional(),
	})).optional(),
	culture: z.array(entry({ tourismPerTurn: z.number(), culturePerTurn: z.number() })).optional(),
	domination: z.array(entry({ military: z.number() })).optional(),
	religion: z.array(entry({ cities: z.number(), faithPerTurn: z.number() })).optional(),
	diplomatic: z.array(entry({ points: z.number(), required: z.number() })).optional(),
});
