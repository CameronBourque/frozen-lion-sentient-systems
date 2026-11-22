// The MCP tools that change the agent's memory: its plan and its journal. Each
// description is written for the model. docs/design/memory.md has the design.

import type { CallToolResult, McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { addJournalEntry, writePlan } from "../memory/store.js";
import type { ToolContext } from "./context.js";
import { readGameNumber } from "./game-number.js";
import { errorResult, forPlayer, textResult } from "./results.js";

// Every turn's prompt holds the plan and the newest entries, so their length
// costs tokens on every turn.
const PLAN_MAX_LENGTH = 2000;
const ENTRY_MAX_LENGTH = 1000;

const UPDATE_PLAN = `Replace your plan with a new one. Your plan is your current strategy in a few lines: your victory goal, what you are building toward, and the threats you watch. Each turn starts with it, since you remember nothing else between turns.

Change it when your strategy changes, not every turn. Write the whole plan, because it replaces the last one.`;

const ADD_JOURNAL_ENTRY = `Add an entry to your journal for this turn. The journal is your log of what happened: wars, deals, promises, surprises, and lessons. Each turn starts with your newest entries.

Write what a later turn needs to know and can't read from get_state, such as why a rival turned hostile or what you promised. Skip routine moves.`;

export function registerMemoryTools(server: McpServer, context: ToolContext): void {
	const { client, player, memory, logger } = context;

	server.registerTool("update_plan", {
		description: UPDATE_PLAN,
		inputSchema: z.object({ plan: z.string().min(1).max(PLAN_MAX_LENGTH).describe("Your whole plan.") }),
	}, ({ plan }) => forPlayer(client, player, (playerID) => {
		const failed = tryWrite(() => writePlan(memory(playerID), plan), "plan");

		logger.decision("plan", `update_plan: ${plan}`, { tool: "update_plan", player: playerID, plan, ok: !failed });

		return Promise.resolve(failed ?? textResult("Saved your plan."));
	}));

	server.registerTool("add_journal_entry", {
		description: ADD_JOURNAL_ENTRY,
		inputSchema: z.object({ entry: z.string().min(1).max(ENTRY_MAX_LENGTH).describe("The entry's text.") }),
	}, ({ entry }) => forPlayer(client, player, async (playerID) => {
		const turn = await readGameNumber(client, "Game.GetCurrentGameTurn()", "turn");

		if (!turn.ok) {
			return errorResult(turn.error);
		}

		const failed = tryWrite(() => addJournalEntry(memory(playerID), { turn: turn.value, text: entry }), "journal");

		logger.decision("journal", `add_journal_entry: ${entry}`, { tool: "add_journal_entry", player: playerID, turn: turn.value, entry, ok: !failed });

		return failed ?? textResult(`Added the entry to your journal for turn ${turn.value}.`);
	}));
}

// A memory file the bridge can't write, such as one on a full disk, fails the
// tool, not the bridge.
function tryWrite(write: () => void, what: string): CallToolResult | undefined {
	try {
		write();

		return undefined;
	} catch (error) {
		return errorResult(`Couldn't save your ${what}: ${(error as Error).message}`);
	}
}
