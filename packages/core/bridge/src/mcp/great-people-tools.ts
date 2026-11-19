// The MCP tools on the Great People and Great Works screens: recruit, pass, or
// patronize a great person, move a great work, and choose an artifact. Each
// description is written for the model.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { passGreatPerson, patronizeGreatPerson, recruitGreatPerson } from "../actions/great-people.js";
import { chooseArtifact, moveGreatWork } from "../actions/great-works.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const RECRUIT_GREAT_PERSON = `Act on a great person on the Great People screen, a type such as GREAT_PERSON_INDIVIDUAL_ARYABHATA.

- recruit, the default: recruit with your points, a great person from get_choices' greatPeople.
- pass: pass on a great person from greatPeople.
- patronize: recruit with gold or faith in yield, when get_state's greatPeople entry has patronage with can true for that yield.

A refusal gives the screen's Cannot Recruit text, or the cost and your points.`;

const MOVE_GREAT_WORK = `Move one of your great works to a slot, as the Great Works screen does. A move into a filled slot swaps the two works.

Take the cityID, building, and slot from a move that get_great_work_moves gives for the work. A refusal names why, such as a work that is locked or a slot that doesn't take its kind.`;

const CHOOSE_ARTIFACT = `Choose whose artifact your digging archaeologist uncovers, a player from the options of get_choices' artifacts.`;

export function registerGreatPeopleTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "recruit_great_person", RECRUIT_GREAT_PERSON, z.object({
		greatPerson: z.string().describe("The great person's type, such as GREAT_PERSON_INDIVIDUAL_ARYABHATA."),
		action: z.enum(["recruit", "pass", "patronize"]).optional(),
		yield: z.enum(["gold", "faith"]).optional().describe("For patronize."),
	}), (playerID, { greatPerson, action, yield: yieldKey }) => {
		if (action === "pass") {
			return passGreatPerson(client, playerID, greatPerson);
		}

		if (action !== "patronize") {
			return recruitGreatPerson(client, playerID, greatPerson);
		}

		return yieldKey === undefined
			? Promise.resolve({ ok: false, reason: "Give patronize a yield, gold or faith." })
			: patronizeGreatPerson(client, playerID, greatPerson, yieldKey);
	});
	registerAction(server, context, "move_great_work", MOVE_GREAT_WORK, z.object({
		workIndex: z.int().describe("The work's index, from get_state's greatWorks."),
		cityID: z.int().describe("The slot's city id, from get_great_work_moves."),
		building: z.string().describe("The slot's building, such as BUILDING_MUSEUM_ART."),
		slot: z.int().describe("The slot's index in its building."),
	}), (playerID, { workIndex, cityID, building, slot }) => moveGreatWork(client, playerID, workIndex, { city: cityID, building, slot }));
	registerAction(server, context, "choose_artifact", CHOOSE_ARTIFACT, z.object({
		player: z.int().describe("The player, from the artifact's options."),
	}), (playerID, { player }) => chooseArtifact(client, playerID, player));
}
