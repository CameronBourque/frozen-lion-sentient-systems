// Plays one agent turn: reads the state and memory, sends the turn message,
// and runs the model's tool calls until end_turn goes through or a limit.
// docs/design/agents/turn-loop.md has the design.

import type { Client } from "@modelcontextprotocol/client";
import type { ModelMessage, ToolModelMessage } from "ai";
import type { Limits, ModelSetting } from "../config.js";
import type { LogFields, Logger } from "../log.js";
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
	limits: Limits;
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

// How each limit reads in the log when the turn reaches it.
const LIMIT_TEXT: Record<keyof Limits, (value: number) => string> = {
	retriesPerAction: (value) => `It reached the retries per action limit of ${value}, with ${value + 1} failures in a row`,
	actionsPerTurn: (value) => `It reached the actions per turn limit of ${value}`,
	turnMinutes: (value) => `It reached the time per turn limit of ${value} minutes`,
};

// What a turn has spent against its limits. failures counts the failed
// actions in a row, and the replies with no tool call.
interface Tally {
	actions: number;
	failures: number;
}

// The signal that ends the turn, at the time limit or a game load, and the
// game-load signal alone, which tells the two apart.
interface Signals {
	turn: AbortSignal;
	load: AbortSignal | undefined;
}

// What the calls of one turn share.
interface TurnRun {
	agent: Agent;
	context: LoopContext;
	signals: Signals;
	actions: Set<string>;
	tally: Tally;
}

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

	const result = await converseInTime(agent, context, messages, signal);

	if (result.ended) {
		agent.endedTurn = turn;
	}

	return result;
}

// The turn's signal aborts at the time limit too, so it stops the model call
// in progress.
async function converseInTime(agent: Agent, context: LoopContext, messages: ModelMessage[], load: AbortSignal | undefined): Promise<TurnResult> {
	const clock = new AbortController();
	const timer = setTimeout(() => clock.abort(), context.limits.turnMinutes * 60_000);
	const turn = load === undefined ? clock.signal : AbortSignal.any([load, clock.signal]);

	try {
		return await converse({ agent, context, signals: { turn, load }, actions: actionTools(agent.definitions), tally: { actions: 0, failures: 0 } }, messages);
	} finally {
		clearTimeout(timer);
	}
}

// The action tools are the ones with a reason, which every action takes.
function actionTools(definitions: ToolDefinition[]): Set<string> {
	return new Set(definitions.filter(({ inputSchema }) => inputSchema.properties?.reason !== undefined).map(({ name }) => name));
}

// Calls the model and runs its tool calls until end_turn goes through, or
// the turn reaches a limit. A reply with no tool call gets a nudge.
async function converse(run: TurnRun, messages: ModelMessage[]): Promise<TurnResult> {
	const { agent, context, signals, tally } = run;

	for (;;) {
		const result = await callModel(context.target, { system: agent.system, messages, tools: agent.definitions, signal: signals.turn });
		// An aborted call fails, and that failure isn't the model's.
		const ended = endedBySignal(run);

		if (ended !== undefined) {
			return ended;
		}

		if (!result.ok) {
			return stopTurn(context.logger, agent, result.error);
		}

		logModelCall(context.logger, context.model, result.reply.usage);
		messages.push(...result.reply.messages);

		if (result.reply.toolCalls.length === 0) {
			tally.failures += 1;

			if (tally.failures > context.limits.retriesPerAction) {
				return reachLimit(run, "retriesPerAction");
			}

			messages.push({ role: "user", content: NUDGE });
			continue;
		}

		const ran = await runCalls(run, result.reply.toolCalls);

		if ("ended" in ran) {
			return ran;
		}

		messages.push(ran);
	}
}

// Runs the calls in order. Once end_turn goes through, it's another
// player's turn, so the rest don't run. After a game load, the rest would act
// in the new game, so they don't run either, and none run past a limit.
async function runCalls(run: TurnRun, calls: ToolCall[]): Promise<TurnResult | ToolModelMessage> {
	const { agent, context, signals, actions, tally } = run;
	const { client, logger } = context;
	const message: ToolModelMessage = { role: "tool", content: [] };

	for (const call of calls) {
		const ended = endedBySignal(run);

		if (ended !== undefined) {
			return ended;
		}

		const output = await callTool(agent.tools, call.name, call.input);

		// The failure is the text the model gets, which says why, such as a
		// game that didn't answer. The message keeps its first line.
		const outcome = output.isError ? `failed: ${output.text.split("\n")[0]}` : "done";

		logger.debug("tool_call", `${call.name}: ${outcome}`, { player: agent.playerID, tool: call.name, input: call.input, ok: !output.isError, ...(output.isError ? { failure: output.text } : {}) });

		if (call.name === END_TURN && !output.isError) {
			return { ended: true };
		}

		const limit = actions.has(call.name) ? countAction(tally, output.isError, context.limits) : undefined;

		if (limit !== undefined) {
			return reachLimit(run, limit);
		}

		message.content.push({
			type: "tool-result",
			toolCallId: call.id,
			toolName: call.name,
			output: { type: output.isError ? "error-text" : "text", value: output.text },
		});

		// A failed call may mean the game stopped answering, and the next
		// call or model call would only fail the same way. The wait ends
		// only when the game answers or the turn's signal aborts.
		if (output.isError && !await waitForGame(client, logger, agent.playerID, signals.turn, context.gameWaitMs)) {
			return endedBySignal(run) as TurnResult;
		}
	}

	return message;
}

// Adds an action to the tally, and returns the limit it reaches, if any. A
// success resets the failures in a row.
function countAction(tally: Tally, failed: boolean, limits: Limits): keyof Limits | undefined {
	tally.actions += 1;
	tally.failures = failed ? tally.failures + 1 : 0;

	if (tally.failures > limits.retriesPerAction) {
		return "retriesPerAction";
	}

	return tally.actions >= limits.actionsPerTurn ? "actionsPerTurn" : undefined;
}

// A game load cancels the turn, and the time limit stops it.
function endedBySignal(run: TurnRun): TurnResult | undefined {
	if (run.signals.load?.aborted === true) {
		return cancelTurn(run.context.logger, run.agent);
	}

	return run.signals.turn.aborted ? reachLimit(run, "turnMinutes") : undefined;
}

function reachLimit({ agent, context }: TurnRun, limit: keyof Limits): TurnResult {
	return stopTurn(context.logger, agent, LIMIT_TEXT[limit](context.limits[limit]), { limit });
}

function cancelTurn(logger: Logger, agent: Agent): TurnResult {
	logger.info("turn_cancelled", `Player ${agent.playerID}'s turn was cancelled, because a game loaded`, { player: agent.playerID });

	return { ended: false, cancelled: true };
}

function stopTurn(logger: Logger, agent: Agent, reason: string, fields: LogFields = {}): TurnResult {
	logger.warn("turn_stopped", `Player ${agent.playerID}'s turn stopped without an end turn: ${reason}`, { player: agent.playerID, reason, ...fields });

	return { ended: false, reason };
}
