// The MCP tools that change the agent's memory: its plan, its journal, and its
// decision records. Each description is written for the model.
// docs/design/memory.md has the design.

import type { CallToolResult, McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { Logger } from "../log.js";
import { type Memory, addDecision, addJournalEntry, readMemory, setDecisionResult, writePlan } from "../memory/store.js";
import type { TunerClient } from "../tuner/client.js";
import type { ToolContext } from "./context.js";
import { readGameNumber } from "./game-number.js";
import { errorResult, forPlayer, textResult } from "./results.js";

// Every turn's prompt holds the plan, the newest entries, and last turn's
// decisions, so their length costs tokens on every turn.
const PLAN_MAX_LENGTH = 2000;
const ENTRY_MAX_LENGTH = 1000;
const DECISION_MAX_LENGTH = 300;

const UPDATE_PLAN = `Replace your plan with a new one. Your plan is your current strategy in a few lines: your victory goal, what you are building toward, and the threats you watch. Each turn starts with it, since you remember nothing else between turns.

Change it when your strategy changes, not every turn. Write the whole plan, because it replaces the last one.`;

const ADD_JOURNAL_ENTRY = `Add an entry to your journal for this turn. The journal is your log of what happened: wars, deals, promises, surprises, and lessons. Each turn starts with your newest entries.

Write what a later turn needs to know and can't read from get_state, such as why a rival turned hostile or what you promised. Skip routine moves.`;

const RECORD_DECISION = `Record an important decision you made this turn, with your reason, such as a war, a new city's site, a government, or a pantheon. Skip routine moves.

Next turn starts by listing these decisions with their ids, and asks you for each one's result.`;

const RECORD_RESULT = `Record the short-term result of one of last turn's decisions, by the id that the turn message gives it. Say what happened and whether the decision worked, in a sentence or two.`;

const DECISION_TEXT = z.string().min(1).max(DECISION_MAX_LENGTH);

type Written<T> =
	| { ok: true; value: T }
	| { ok: false; result: CallToolResult };

export function registerMemoryTools(server: McpServer, context: ToolContext): void {
	const { client, player, memory, logger } = context;

	server.registerTool("update_plan", {
		description: UPDATE_PLAN,
		inputSchema: z.object({ plan: z.string().min(1).max(PLAN_MAX_LENGTH).describe("Your whole plan.") }),
	}, ({ plan }) => forPlayer(client, player, (playerID) => {
		const written = tryWrite(() => writePlan(memory(playerID), plan), "plan");

		logger.decision("plan", `update_plan: ${plan}`, { tool: "update_plan", player: playerID, plan, ok: written.ok });

		return Promise.resolve(written.ok ? textResult("Saved your plan.") : written.result);
	}));

	server.registerTool("add_journal_entry", {
		description: ADD_JOURNAL_ENTRY,
		inputSchema: z.object({ entry: z.string().min(1).max(ENTRY_MAX_LENGTH).describe("The entry's text.") }),
	}, ({ entry }) => forPlayer(client, player, (playerID) => withTurn(client, (turn) => {
		const written = tryWrite(() => addJournalEntry(memory(playerID), { turn, text: entry }), "journal");

		logger.decision("journal", `add_journal_entry: ${entry}`, { tool: "add_journal_entry", player: playerID, turn, entry, ok: written.ok });

		return written.ok ? textResult(`Added the entry to your journal for turn ${turn}.`) : written.result;
	})));

	server.registerTool("record_decision", {
		description: RECORD_DECISION,
		inputSchema: z.object({
			decision: DECISION_TEXT.describe("What you decided, in one sentence."),
			reason: DECISION_TEXT.describe("Why, in one sentence."),
		}),
	}, ({ decision, reason }) => forPlayer(client, player, (playerID) => withTurn(client, (turn) => {
		const folder = memory(playerID);
		const written = tryWrite(() => addDecision(folder, readDecisions(folder, logger), { turn, decision, reason }), "decision");

		logger.decision("decision", `record_decision: ${decision}`, { tool: "record_decision", player: playerID, turn, decision, reason, ...(written.ok ? { id: written.value } : {}), ok: written.ok });

		return written.ok ? textResult(`Recorded decision ${written.value}.`) : written.result;
	})));

	server.registerTool("record_result", {
		description: RECORD_RESULT,
		inputSchema: z.object({
			id: z.int().min(1).describe("The decision's id."),
			result: DECISION_TEXT.describe("What happened, and whether the decision worked."),
		}),
	}, ({ id, result }) => forPlayer(client, player, (playerID) => {
		const folder = memory(playerID);
		const written = tryWrite(() => setDecisionResult(folder, readDecisions(folder, logger), id, result), "result");
		const found = written.ok && written.value;

		logger.decision("decision_result", `record_result: ${result}`, { tool: "record_result", player: playerID, id, result, ok: found });

		if (!written.ok) {
			return Promise.resolve(written.result);
		}

		return Promise.resolve(found ? textResult(`Recorded the result of decision ${id}.`) : errorResult(`No decision has the id ${id}.`));
	}));
}

// Runs the tool with the game's current turn, or fails with why the game gave
// none.
async function withTurn(client: TunerClient, run: (turn: number) => CallToolResult): Promise<CallToolResult> {
	const turn = await readGameNumber(client, "Game.GetCurrentGameTurn()", "turn");

	return turn.ok ? run(turn.value) : errorResult(turn.error);
}

// The records the next write builds on, after a file the store can't read has
// moved aside.
function readDecisions(folder: string, logger: Logger): Memory["decisions"] {
	const { memory, warnings } = readMemory(folder, new Date());

	for (const warning of warnings) {
		logger.warn("memory_unreadable", warning, { folder });
	}

	return memory.decisions;
}

// A memory file the bridge can't write, such as one on a full disk, fails the
// tool, not the bridge.
function tryWrite<T>(write: () => T, what: string): Written<T> {
	try {
		return { ok: true, value: write() };
	} catch (error) {
		return { ok: false, result: errorResult(`Couldn't save your ${what}: ${(error as Error).message}`) };
	}
}
