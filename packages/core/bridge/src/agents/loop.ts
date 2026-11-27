// Plays one agent turn: reads the state and memory, sends the turn message,
// and runs the model's tool calls until end_turn goes through.
// docs/design/agents/turn-loop.md has the design.

import type { Client } from "@modelcontextprotocol/client";
import type { ModelMessage, ToolModelMessage } from "ai";
import type { ModelSetting } from "../config.js";
import type { Logger } from "../log.js";
import { callTool } from "../mcp/in-process.js";
import { readMemory, startMemory } from "../memory/store.js";
import { type ModelTarget, type ToolCall, type ToolDefinition, callModel } from "../model/client.js";
import { logModelCall } from "../model/usage.js";
import { readState } from "../state/state.js";
import type { TunerClient } from "../tuner/client.js";
import { waitForGame } from "./game-wait.js";
import { turnMessage } from "./prompt.js";

// What stays the same for an agent from turn to turn. first is true until
// its first turn after the bridge starts.
export interface Agent {
	playerID: number;
	system: string;
	tools: Client;
	definitions: ToolDefinition[];
	memoryFolder: string;
	first: boolean;
	// The game turn of its last end turn that went through.
	endedTurn?: number;
}

export interface LoopContext {
	client: TunerClient;
	logger: Logger;
	target: ModelTarget;
	model: ModelSetting;
	journalEntries: number;
	now: () => Date;
	// How long a turn waits between checks on a game that doesn't answer.
	gameWaitMs?: number;
}

// A turn that stops without end_turn leaves the game waiting on the agent. A
// skipped turn was already ended, so the game has moved on. A cancelled turn
// belongs to a game that is no longer loaded.
export type TurnResult =
	| { ended: true }
	| { ended: false; reason: string }
	| { ended: false; skipped: true }
	| { ended: false; cancelled: true };

// again is true when the game started the turn again after cancelling its
// end. signal aborts the turn when a game loads.
export interface TurnOptions {
	again?: boolean;
	signal?: AbortSignal;
}

const END_TURN = "end_turn";

const NUDGE = "You wrote no tool call. Take your next action, or call end_turn when you are done.";

// A turn started again keeps its turn number, so the agent plays it and is
// told so.
export async function playTurn(agent: Agent, context: LoopContext, { again = false, signal }: TurnOptions = {}): Promise<TurnResult> {
	const { client, logger, now } = context;
	const state = await readState(client, agent.playerID);

	if (signal?.aborted === true) {
		return cancelTurn(logger, agent);
	}

	if (!state.ok) {
		return stopTurn(logger, agent, `The state couldn't be read: ${state.error}`);
	}

	const turn = state.value.turn;

	// A signal on a turn the agent already ended, such as from the resync,
	// would send a second end turn for it.
	if (!again && agent.endedTurn === turn) {
		logger.info("turn_skipped", `Player ${agent.playerID} already ended turn ${turn}`, { player: agent.playerID, turn });

		return { ended: false, skipped: true };
	}

	// The first turn moves memory from another game aside.
	const read = agent.first ? startMemory(agent.memoryFolder, turn, now()) : readMemory(agent.memoryFolder, now());

	agent.first = false;
	read.warnings.forEach((warning) => logger.warn("memory_warning", warning, { player: agent.playerID }));

	const messages: ModelMessage[] = [{ role: "user", content: turnMessage({ state: state.value, memory: read.memory, journalEntries: context.journalEntries, again }) }];

	const result = await converse(agent, context, messages, signal);

	if (result.ended) {
		agent.endedTurn = turn;
	}

	return result;
}

// Calls the model and runs its tool calls until end_turn goes through. A
// reply with no tool call gets one nudge, and a second in a row stops.
async function converse(agent: Agent, context: LoopContext, messages: ModelMessage[], signal: AbortSignal | undefined): Promise<TurnResult> {
	const { logger } = context;
	let nudged = false;

	for (;;) {
		const result = await callModel(context.target, { system: agent.system, messages, tools: agent.definitions, signal });

		// An aborted call fails, and that failure isn't the model's.
		if (signal?.aborted === true) {
			return cancelTurn(logger, agent);
		}

		if (!result.ok) {
			return stopTurn(logger, agent, result.error);
		}

		logModelCall(logger, context.model, result.reply.usage);
		messages.push(...result.reply.messages);

		if (result.reply.toolCalls.length === 0) {
			if (nudged) {
				return stopTurn(logger, agent, `The model called no tool twice in a row. It wrote: ${result.reply.text}`);
			}

			nudged = true;
			messages.push({ role: "user", content: NUDGE });
			continue;
		}

		nudged = false;

		const ran = await runCalls(agent, context, result.reply.toolCalls, signal);

		if (ran === "cancelled") {
			return cancelTurn(logger, agent);
		}

		if (ran.ended) {
			return { ended: true };
		}

		messages.push(ran.message);
	}
}

// Runs the calls in order. Once end_turn goes through, it's another
// player's turn, so the rest don't run. After a game load, the rest would act
// in the new game, so they don't run either.
async function runCalls(agent: Agent, context: LoopContext, calls: ToolCall[], signal: AbortSignal | undefined): Promise<{ ended: true } | { ended: false; message: ToolModelMessage } | "cancelled"> {
	const { client, logger } = context;
	const message: ToolModelMessage = { role: "tool", content: [] };

	for (const call of calls) {
		if (signal?.aborted === true) {
			return "cancelled";
		}

		const output = await callTool(agent.tools, call.name, call.input);

		logger.debug("tool_call", `${call.name}: ${output.isError ? "failed" : "done"}`, { player: agent.playerID, tool: call.name, input: call.input, ok: !output.isError });

		if (call.name === END_TURN && !output.isError) {
			return { ended: true };
		}

		message.content.push({
			type: "tool-result",
			toolCallId: call.id,
			toolName: call.name,
			output: { type: output.isError ? "error-text" : "text", value: output.text },
		});

		// A failed call may mean the game stopped answering, and the next
		// call or model call would only fail the same way.
		if (output.isError && !await waitForGame(client, logger, agent.playerID, signal, context.gameWaitMs)) {
			return "cancelled";
		}
	}

	return { ended: false, message };
}

function cancelTurn(logger: Logger, agent: Agent): TurnResult {
	logger.info("turn_cancelled", `Player ${agent.playerID}'s turn was cancelled, because a game loaded`, { player: agent.playerID });

	return { ended: false, cancelled: true };
}

function stopTurn(logger: Logger, agent: Agent, reason: string): TurnResult {
	logger.warn("turn_stopped", `Player ${agent.playerID}'s turn stopped without an end turn: ${reason}`, { player: agent.playerID, reason });

	return { ended: false, reason };
}
