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
}

// A turn that stops without end_turn leaves the game waiting on the agent. A
// skipped turn was already ended, so the game has moved on.
export type TurnResult =
	| { ended: true }
	| { ended: false; reason: string }
	| { ended: false; skipped: true };

const END_TURN = "end_turn";

const NUDGE = "You wrote no tool call. Take your next action, or call end_turn when you are done.";

// again is true when the game started the turn again after cancelling its
// end, so the turn number stays the same and the agent plays it.
export async function playTurn(agent: Agent, context: LoopContext, again = false): Promise<TurnResult> {
	const { client, logger, now } = context;
	const state = await readState(client, agent.playerID);

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

	const messages: ModelMessage[] = [{ role: "user", content: turnMessage({ state: state.value, memory: read.memory, journalEntries: context.journalEntries }) }];

	const result = await converse(agent, context, messages);

	if (result.ended) {
		agent.endedTurn = turn;
	}

	return result;
}

// Calls the model and runs its tool calls until end_turn goes through. A
// reply with no tool call gets one nudge, and a second in a row stops.
async function converse(agent: Agent, context: LoopContext, messages: ModelMessage[]): Promise<TurnResult> {
	const { logger } = context;
	let nudged = false;

	for (;;) {
		const result = await callModel(context.target, { system: agent.system, messages, tools: agent.definitions });

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

		const ran = await runCalls(agent, logger, result.reply.toolCalls);

		if (ran.ended) {
			return { ended: true };
		}

		messages.push(ran.message);
	}
}

// Runs the calls in order. Once end_turn goes through, it's another
// player's turn, so the rest don't run.
async function runCalls(agent: Agent, logger: Logger, calls: ToolCall[]): Promise<{ ended: true } | { ended: false; message: ToolModelMessage }> {
	const message: ToolModelMessage = { role: "tool", content: [] };

	for (const call of calls) {
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
	}

	return { ended: false, message };
}

function stopTurn(logger: Logger, agent: Agent, reason: string): TurnResult {
	logger.warn("turn_stopped", `Player ${agent.playerID}'s turn stopped without an end turn: ${reason}`, { player: agent.playerID, reason });

	return { ended: false, reason };
}
