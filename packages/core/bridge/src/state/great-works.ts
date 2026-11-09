// The schema for the great works section of the state, as the Great Works
// screen shows it. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateGreatWorks.lua.

import { z } from "zod";
import { YIELD_AMOUNT } from "../schemas.js";

const CITY = z.object({ id: z.number(), name: z.string().describe("In the game's language.") });

const WORK = z.object({
	index: z.number().describe("The game's index of this work, which a move names."),
	type: z.string(),
	name: z.string().describe("In the game's language."),
	objectType: z.string().describe("The kind of work, such as GREATWORKOBJECT_SCULPTURE."),
	era: z.string().optional().describe("The era of an artifact, or of any work that has one."),
	tourism: z.number().describe("The tourism the work gives while it is in a building."),
	yields: z.array(YIELD_AMOUNT),
	lockedTurns: z.number().describe(
		"The turns before the work can be moved again. Art is locked for a time after it is created or moved, and other works are never locked.",
	),
	movable: z.boolean().describe(
		"Whether the screen lets the work be dragged: not locked, and an artifact only when its museum is full.",
	),
});

const SLOT = z.object({
	city: CITY,
	building: z.string().describe("The type of the building that holds the slot."),
	slot: z.number().describe("The slot's index in its building."),
	kind: z.string().describe("The kind of slot, such as GREATWORKSLOT_ART."),
	accepts: z.array(z.string()).describe(
		"The object types of works the slot takes, such as GREATWORKOBJECT_SCULPTURE, as the empty slot's tooltip lists them. A palace slot takes every type.",
	),
	themed: z.boolean().optional().describe(
		"Whether the work counts toward the building's theme. Left out for an empty slot and for a building with no theme.",
	),
	work: WORK.optional().describe("The work in the slot. Left out for an empty slot."),
});

const THEME_RULES = z.object({
	uniqueCreators: z.boolean().describe("A full theme needs works by different creators."),
	sameObjectType: z.boolean().describe("A full theme needs works of one object type."),
	sameEra: z.boolean().describe("A full theme needs works of one era."),
	uniqueCivilizations: z.boolean().describe("A full theme needs works from different civilizations."),
	yieldMultiplier: z.number().describe("The percent a full theme adds to the works' yields."),
	tourismMultiplier: z.number().describe("The percent a full theme adds to the works' tourism."),
});

const THEME = z.object({
	bonus: z.string().describe("The theming bonus text, in the game's language."),
	complete: z.boolean().describe("Whether the building has its theming bonus."),
	themedWorks: z.number().describe(
		"The works that count toward the theme, as the screen's progress shows, out of the building's spaces. With auto theming it is the number of works.",
	),
	rules: THEME_RULES.optional().describe(
		"What a full theme needs, from the game's data. All the slots must hold works, and the works must follow every rule listed. Left out when the game has no rules for the building, as for an auto themed one.",
	),
});

const BUILDING = z.object({
	city: CITY,
	type: z.string(),
	name: z.string().describe("In the game's language."),
	spaces: z.number().describe("The number of slots."),
	works: z.number().describe("The number of slots with a work."),
	theme: THEME.optional().describe("The building's theming bonus. Left out for a building with none, as the screen shows no label for it."),
	yields: z.array(YIELD_AMOUNT).describe("What the works in the building give, for each yield above 0."),
	tourism: z.number().describe("The tourism of the works in the building, with the religious tourism."),
});

export const GREAT_WORKS = z.object({
	slots: z.array(SLOT).describe("Every great work slot of the player's cities, by city and building."),
	buildings: z.array(BUILDING).describe("Every building with great work slots."),
	works: z.number().describe("The great works total of the screen."),
	spaces: z.number().describe("The display spaces total of the screen."),
	provides: z.array(YIELD_AMOUNT).describe(
		"What the works provide in total, as the screen shows it. The tourism is a yield of type TOURISM.",
	),
});
