// Plays one agent turn: reads the state and memory, has the runner play the
// turn message, and ends the turn with force at a limit.
// docs/design/agents/turn-loop/README.md has the design.

import type { Client } from "@modelcontextprotocol/client";
import { endTurn } from "../actions/turn.js";
import type { Limits, ModelSetting } from "../config.js";
import type { LogFields, Logger } from "../log.js";
import type { ToolContext } from "../mcp/context.js";
import { readMemory, startMemory } from "../memory/store.js";
import type { ToolDefinition } from "../model/client.js";
import { readState } from "../state/state.js";
import type { TunerClient } from "../tuner/client.js";
import { turnMessage } from "./prompt.js";
import type { AgentRunner, TurnEnd } from "./runners/shared.js";
import type { Spend } from "./spend.js";

// What stays the same for an agent from turn to turn. first is true until
// its first turn after the bridge starts.
export interface Agent {
	playerID: number;
	system: string;
	tools: Client;
	definitions: ToolDefinition[];
	memoryFolder: string;
	// What the tools act with, for a runner that serves them over HTTP.
	toolContext: ToolContext;
	first: boolean;
	// The game turn of its last end turn that went through.
	endedTurn?: number;
}

export interface LoopContext {
	client: TunerClient;
	logger: Logger;
	runner: AgentRunner;
	model: ModelSetting;
	journalEntries: number;
	limits: Limits;
	// What every agent's model calls spent since the bridge started.
	runSpend: Spend;
	now: () => Date;
	// How long a turn waits between checks on a game that doesn't answer.
	gameWaitMs?: number;
}

// A turn that stops without an end turn leaves the game waiting on the agent,
// and stopRun asks the bridge to stop too. A skipped turn was already ended, so
// the game has moved on. A cancelled turn belongs to a game that is no longer
// loaded, or to a bridge that is stopping.
export type TurnResult =
	| { ended: true }
	| { ended: false; reason: string; stopRun?: true }
	| { ended: false; skipped: true }
	| { ended: false; cancelled: true };

// again is true when the game started the turn again after cancelling its
// end. signal cancels the turn, and its abort reason says why.
export interface TurnOptions {
	again?: boolean;
	signal?: AbortSignal;
}

// Why a turn is cancelled, by the reason its signal is aborted with. A signal
// aborted with no reason is a game load.
const CANCEL_TEXT = {
	load: "a game loaded",
	stop: "the bridge is stopping",
};

export type CancelReason = keyof typeof CANCEL_TEXT;

// How each limit reads in the log when the turn reaches it.
const LIMIT_TEXT: Record<keyof Limits, (limits: Limits) => string> = {
	retriesPerAction: ({ retriesPerAction }) => `It reached the retries per action limit of ${retriesPerAction}, with ${retriesPerAction + 1} failures in a row`,
	actionsPerTurn: ({ actionsPerTurn }) => `It reached the actions per turn limit of ${actionsPerTurn}`,
	turnMinutes: ({ turnMinutes }) => `It reached the time per turn limit of ${turnMinutes} minutes`,
	tokensPerTurn: ({ tokensPerTurn }) => `It reached the tokens per turn limit of ${tokensPerTurn}`,
	costPerTurn: ({ costPerTurn }) => `It reached the cost per turn limit of $${costPerTurn}`,
	tokensPerRun: ({ tokensPerRun }) => `The run reached the tokens per run limit of ${tokensPerRun}`,
	costPerRun: ({ costPerRun }) => `The run reached the cost per run limit of $${costPerRun}`,
};

// The abort reason of a turn that reaches its time limit. Any other reason
// cancels the turn.
const TIME_LIMIT: keyof Limits = "turnMinutes";

// A turn started again keeps its turn number, so the agent plays it and is
// told so.
export async function playTurn(agent: Agent, context: LoopContext, { again = false, signal }: TurnOptions = {}): Promise<TurnResult> {
	const { client, logger, now } = context;
	const state = await readState(client, agent.playerID);

	if (signal?.aborted === true) {
		return cancelTurn(logger, agent, signal);
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

	const message = turnMessage({ state: state.value, memory: read.memory, journalEntries: context.journalEntries, again });
	const result = await runInTime(agent, context, message, signal);

	if (result.ended) {
		agent.endedTurn = turn;
	}

	return result;
}

// The turn's signal aborts at the time limit too, so it stops the call in
// progress. A combined signal takes the reason of the first one to abort.
async function runInTime(agent: Agent, context: LoopContext, message: string, cancel: AbortSignal | undefined): Promise<TurnResult> {
	const clock = new AbortController();
	const timer = setTimeout(() => clock.abort(TIME_LIMIT), context.limits.turnMinutes * 60_000);
	const signal = cancel === undefined ? clock.signal : AbortSignal.any([cancel, clock.signal]);

	try {
		const { end } = await context.runner.runTurn({ agent, message, context }, signal);

		return await finishTurn(agent, context, end, signal);
	} finally {
		clearTimeout(timer);
	}
}

// Turns how the runner's turn ended into the turn's result. A game load or a
// stop cancels the turn, and the time limit forces its end.
async function finishTurn(agent: Agent, context: LoopContext, end: TurnEnd, signal: AbortSignal): Promise<TurnResult> {
	const { logger } = context;

	if ("ended" in end) {
		return end;
	}

	if ("runLimit" in end) {
		return stopRun(logger, agent, LIMIT_TEXT[end.runLimit](context.limits), { limit: end.runLimit });
	}

	if ("failed" in end) {
		return end.stopRun ? stopRun(logger, agent, end.failed) : stopTurn(logger, agent, end.failed);
	}

	if ("limit" in end) {
		return await reachLimit(agent, context, end.limit);
	}

	return signal.reason === TIME_LIMIT ? await reachLimit(agent, context, TIME_LIMIT) : cancelTurn(logger, agent, signal);
}

// Ends the turn with force, so one stuck turn can't stop the game, and warns
// of the blockers and the units it skipped. A forced end that fails, such as
// with a deal waiting, stops the turn, and the game waits on the agent.
async function reachLimit(agent: Agent, context: LoopContext, limit: keyof Limits): Promise<TurnResult> {
	const { client, logger } = context;
	const player = agent.playerID;
	const reason = LIMIT_TEXT[limit](context.limits);
	const result = await endTurn(client, player, true);

	if (!result.ok) {
		return stopTurn(logger, agent, `${reason}, and the forced end turn failed: ${result.reason}`, { limit });
	}

	logger.warn("turn_forced", `Player ${player}'s turn was ended with force: ${reason}`, { player, reason, limit });

	const blockers = result.skipped?.list ?? [];
	const units = result.skipped?.units ?? [];

	if (blockers.length > 0) {
		logger.warn("blockers_skipped", `Player ${player}'s forced end turn skipped the blockers ${blockers.map(({ type }) => type).join(", ")}`, { player, blockers });
	}

	if (units.length > 0) {
		logger.warn("units_skipped", `Player ${player}'s forced end turn skipped the units that needed orders: ${units.join(", ")}`, { player, units });
	}

	return { ended: true };
}

function cancelTurn(logger: Logger, agent: Agent, signal: AbortSignal): TurnResult {
	const reason: CancelReason = signal.reason === "stop" ? "stop" : "load";

	logger.info("turn_cancelled", `Player ${agent.playerID}'s turn was cancelled, because ${CANCEL_TEXT[reason]}`, { player: agent.playerID });

	return { ended: false, cancelled: true };
}

function stopTurn(logger: Logger, agent: Agent, reason: string, fields: LogFields = {}): TurnResult {
	logger.warn("turn_stopped", `Player ${agent.playerID}'s turn stopped without an end turn: ${reason}`, { player: agent.playerID, reason, ...fields });

	return { ended: false, reason };
}

// The bridge stops once the turn returns, as it does for the stop key.
function stopRun(logger: Logger, agent: Agent, reason: string, fields: LogFields = {}): TurnResult {
	stopTurn(logger, agent, reason, { ...fields, stopRun: true });

	return { ended: false, reason, stopRun: true };
}
