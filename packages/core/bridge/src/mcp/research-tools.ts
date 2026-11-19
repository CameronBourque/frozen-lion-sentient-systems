// The MCP tools that set the tech and the civic in research. Each description
// is written for the model. docs/design/core/mod/actions/research.md has the
// actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { ActionResult } from "../actions/actions.js";
import { queueCivic, queueResearch, setCivic, setResearch } from "../actions/research.js";
import type { TunerClient } from "../tuner/client.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

type Research = (client: TunerClient, playerID: number, type: string) => Promise<ActionResult>;

// Each kind of research, with its tool, its example, and its calls. Techs and
// civics work the same way, as the tree screens do.
const KINDS: { tool: string; kind: string; choice: string; tree: string; example: string; set: Research; queue: Research }[] = [
	{ tool: "set_research", kind: "tech", choice: "techs", tree: "get_tech_tree", example: "TECH_MINING", set: setResearch, queue: queueResearch },
	{ tool: "set_civic", kind: "civic", choice: "civics", tree: "get_civic_tree", example: "CIVIC_MYSTICISM", set: setCivic, queue: queueCivic },
];

function describeResearch({ kind, choice, tree, example }: (typeof KINDS)[number]): string {
	return `Research a ${kind} and the prerequisites it needs, as a click on the tree screen does. The type is from get_choices' ${choice} or from ${tree}, such as ${example}, so you can plan several ${kind}s ahead.

Without queue, the path replaces the queue. With queue, it goes to the end, and anything already queued is skipped. A refusal names a ${kind} you have already, one the tree doesn't reveal yet, or one with no path.`;
}

export function registerResearchTools(server: McpServer, context: ToolContext): void {
	for (const research of KINDS) {
		registerAction(server, context, research.tool, describeResearch(research), z.object({
			type: z.string().describe(`The ${research.kind}'s type, such as ${research.example}.`),
			queue: z.boolean().optional().describe("Add to the end of the queue instead of replacing it."),
		}), (playerID, { type, queue }) => (queue === true ? research.queue : research.set)(context.client, playerID, type));
	}
}
