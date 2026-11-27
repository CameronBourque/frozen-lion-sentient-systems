// Plays one agent turn: reads the state and memory, sends the turn message,
// and runs the model's tool calls until end_turn goes through or a limit
// forces the end. docs/design/agents/turn-loop/README.md has the design.

import type { Client } from "@modelcontextprotocol/client";
import type { ModelMessage, ToolModelMessage } from "ai";
import { endTurn } from "../actions/turn.js";
import type { Limits, ModelSetting } from "../config.js";
import type { LogFields, Logger } from "../log.js";
import { callTool } from "../mcp/in-process.js";
import { readMemory, startMemory } from "../memory/store.js";
import { type ModelTarget, type ToolCall, type ToolDefinition, type Usage, callModel } from "../model/client.js";
import { logModelCall } from "../model/usage.js";
import { readState } from "../state/state.js";
import type { TunerClient } from "../tuner/client.js";
import { waitForGame } from "./game-wait.js";
import { turnMessage } from "./prompt.js";
import { type Spend, addSpend, noSpend, reachedSpendLimit } from "./spend.js";

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

const END_TURN = "end_turn";

const NUDGE = "You wrote no tool call. Take your next action, or call end_turn when you are done.";

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

// The model call failure that stops the run: a plan's usage limit, which fails
// every call until the plan resets.
const RUN_FAILURE = "limit";

// What a turn has spent against its limits. failures counts the failed
// actions in a row, and the replies with no tool call.
interface Tally {
	actions: number;
	failures: number;
	spend: Spend;
}

// The abort reason of a turn that reaches its time limit. Any other reason
// cancels the turn.
const TIME_LIMIT: keyof Limits = "turnMinutes";

// What the calls of one turn share. signal aborts at the time limit or a
// cancel, and its reason says which.
interface TurnRun {
	agent: Agent;
	context: LoopContext;
	signal: AbortSignal;
	actions: Set<string>;
	tally: Tally;
}

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

	const messages: ModelMessage[] = [{ role: "user", content: turnMessage({ state: state.value, memory: read.memory, journalEntries: context.journalEntries, again }) }];

	const result = await converseInTime(agent, context, messages, signal);

	if (result.ended) {
		agent.endedTurn = turn;
	}

	return result;
}

// The turn's signal aborts at the time limit too, so it stops the model call
// in progress. A combined signal takes the reason of the first one to abort.
async function converseInTime(agent: Agent, context: LoopContext, messages: ModelMessage[], cancel: AbortSignal | undefined): Promise<TurnResult> {
	const clock = new AbortController();
	const timer = setTimeout(() => clock.abort(TIME_LIMIT), context.limits.turnMinutes * 60_000);
	const signal = cancel === undefined ? clock.signal : AbortSignal.any([cancel, clock.signal]);

	try {
		return await converse({ agent, context, signal, actions: actionTools(agent.definitions), tally: { actions: 0, failures: 0, spend: noSpend() } }, messages);
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
	const { agent, context, signal, tally } = run;

	for (;;) {
		const result = await callModel(context.target, { system: agent.system, messages, tools: agent.definitions, signal });
		// An aborted call fails, and that failure isn't the model's.
		const ended = await endedBySignal(run);

		if (ended !== undefined) {
			return ended;
		}

		if (!result.ok) {
			return result.kind === RUN_FAILURE ? stopRun(context.logger, agent, result.error) : stopTurn(context.logger, agent, result.error);
		}

		logModelCall(context.logger, context.model, result.reply.usage);

		const spent = await spendCall(run, result.reply.usage);

		if (spent !== undefined) {
			return spent;
		}

		messages.push(...result.reply.messages);

		if (result.reply.toolCalls.length === 0) {
			tally.failures += 1;

			if (tally.failures > context.limits.retriesPerAction) {
				return await reachLimit(run, "retriesPerAction");
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

// Adds the call to the turn's and the run's spend. At a spending limit, the
// reply's tool calls don't run. A run at its limit stops, which wins over a
// turn at its limit, since a forced end would start more turns.
async function spendCall(run: TurnRun, usage: Usage): Promise<TurnResult | undefined> {
	const { agent, context, tally } = run;

	addSpend(tally.spend, usage, context.model.price);
	addSpend(context.runSpend, usage, context.model.price);

	const runLimit = reachedSpendLimit(context.runSpend, context.limits, "run");

	if (runLimit !== undefined) {
		return stopRun(context.logger, agent, LIMIT_TEXT[runLimit](context.limits), { limit: runLimit });
	}

	const turnLimit = reachedSpendLimit(tally.spend, context.limits, "turn");

	return turnLimit === undefined ? undefined : await reachLimit(run, turnLimit);
}

// Runs the calls in order. Once end_turn goes through, it's another
// player's turn, so the rest don't run. After a cancel, the rest would act in
// a new game or a stopped run, so they don't run either, and none run past a
// limit. A cancel waits for the call in progress, so no Lua command is cut off.
async function runCalls(run: TurnRun, calls: ToolCall[]): Promise<TurnResult | ToolModelMessage> {
	const { agent, context, signal, actions, tally } = run;
	const { client, logger } = context;
	const message: ToolModelMessage = { role: "tool", content: [] };

	for (const call of calls) {
		const ended = await endedBySignal(run);

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
			return await reachLimit(run, limit);
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
		if (output.isError && !await waitForGame(client, logger, agent.playerID, signal, context.gameWaitMs)) {
			return await endedBySignal(run) as TurnResult;
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

// A game load or a stop cancels the turn, and the time limit forces its end.
async function endedBySignal(run: TurnRun): Promise<TurnResult | undefined> {
	const { signal } = run;

	if (!signal.aborted) {
		return undefined;
	}

	return signal.reason === TIME_LIMIT ? await reachLimit(run, TIME_LIMIT) : cancelTurn(run.context.logger, run.agent, signal);
}

// Ends the turn with force, so one stuck turn can't stop the game, and warns
// of the blockers and the units it skipped. A forced end that fails, such as
// with a deal waiting, stops the turn, and the game waits on the agent.
async function reachLimit({ agent, context }: TurnRun, limit: keyof Limits): Promise<TurnResult> {
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
