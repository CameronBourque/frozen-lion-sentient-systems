// Runs one agent turn's tool loop, and the bridge's own runner, which calls the
// model client. docs/design/core/run-modes.md has the design.

import type { ModelMessage, ToolModelMessage } from "ai";
import type { Limits } from "../config.js";
import { type ToolOutput, callTool } from "../mcp/in-process.js";
import { type ModelTarget, type ToolCall, type ToolDefinition, type Usage, callModel } from "../model/client.js";
import { logModelCall } from "../model/usage.js";
import { waitForGame } from "./game-wait.js";
import type { Agent, LoopContext } from "./loop.js";
import { type Spend, type SpendLimit, addSpend, noSpend, reachedSpendLimit } from "./spend.js";

// What a runner gets for one turn. limits are in context.
export interface RunnerTurn {
	agent: Agent;
	message: string;
	context: LoopContext;
}

// How a runner's turn ended. The runner only reports it, and the turn loop
// ends the turn with force, logs, or cancels. aborted means the signal
// aborted, and its reason says why.
export type TurnEnd =
	| { ended: true }
	| { limit: keyof Limits }
	| { runLimit: SpendLimit }
	| { failed: string; stopRun: boolean }
	| { aborted: true };

// spend is what the turn's model calls spent.
export interface RunnerResult {
	end: TurnEnd;
	spend: Spend;
}

// signal aborts at the time limit, a game load, or a stop, and the runner
// stops the call in progress.
export interface AgentRunner {
	runTurn: (turn: RunnerTurn, signal: AbortSignal) => Promise<RunnerResult>;
}

const END_TURN = "end_turn";

const NUDGE = "You wrote no tool call. Take your next action, or call end_turn when you are done.";

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

// What the calls of one turn share, in every runner.
export interface TurnRun {
	agent: Agent;
	context: LoopContext;
	signal: AbortSignal;
	actions: Set<string>;
	tally: Tally;
}

// The API key and subscription token modes share it, each with its model.
export function bridgeRunner(target: ModelTarget): AgentRunner {
	return {
		runTurn: async ({ agent, message, context }, signal) => {
			const run = startRun(agent, context, signal);
			const end = await converse(run, target, [{ role: "user", content: message }]);

			return { end, spend: run.tally.spend };
		},
	};
}

export function startRun(agent: Agent, context: LoopContext, signal: AbortSignal): TurnRun {
	return { agent, context, signal, actions: actionTools(agent.definitions), tally: { actions: 0, failures: 0, spend: noSpend() } };
}

// The action tools are the ones with a reason, which every action takes.
function actionTools(definitions: ToolDefinition[]): Set<string> {
	return new Set(definitions.filter(({ inputSchema }) => inputSchema.properties?.reason !== undefined).map(({ name }) => name));
}

// Calls the model and runs its tool calls until end_turn goes through, or
// the turn reaches a limit. A reply with no tool call gets a nudge.
async function converse(run: TurnRun, target: ModelTarget, messages: ModelMessage[]): Promise<TurnEnd> {
	const { agent, context, signal, tally } = run;

	for (;;) {
		const result = await callModel(target, { system: agent.system, messages, tools: agent.definitions, signal });

		// An aborted call fails, and that failure isn't the model's.
		if (signal.aborted) {
			return { aborted: true };
		}

		if (!result.ok) {
			return { failed: result.error, stopRun: result.kind === RUN_FAILURE };
		}

		logModelCall(context.logger, context.model, result.reply.usage);

		const spent = spendCall(run, result.reply.usage);

		if (spent !== undefined) {
			return spent;
		}

		messages.push(...result.reply.messages);

		if (result.reply.toolCalls.length === 0) {
			tally.failures += 1;

			if (tally.failures > context.limits.retriesPerAction) {
				return { limit: "retriesPerAction" };
			}

			messages.push({ role: "user", content: NUDGE });
			continue;
		}

		const ran = await runCalls(run, result.reply.toolCalls);

		if (!("role" in ran)) {
			return ran;
		}

		messages.push(ran);
	}
}

// Adds the call to the turn's and the run's spend. At a spending limit, the
// reply's tool calls don't run. A run at its limit stops, which wins over a
// turn at its limit, since a forced end would start more turns.
function spendCall({ context, tally }: TurnRun, usage: Usage): TurnEnd | undefined {
	addSpend(tally.spend, usage, context.model.price);
	addSpend(context.runSpend, usage, context.model.price);

	const runLimit = reachedSpendLimit(context.runSpend, context.limits, "run");

	if (runLimit !== undefined) {
		return { runLimit };
	}

	const limit = reachedSpendLimit(tally.spend, context.limits, "turn");

	return limit === undefined ? undefined : { limit };
}

// Runs the calls in order, and stops at the first that ends the turn.
async function runCalls(run: TurnRun, calls: ToolCall[]): Promise<TurnEnd | ToolModelMessage> {
	const message: ToolModelMessage = { role: "tool", content: [] };

	for (const call of calls) {
		const aborted = beforeCall(run);

		if (aborted !== undefined) {
			return aborted;
		}

		const output = await callTool(run.agent.tools, call.name, call.input);
		const end = await afterCall(run, call.name, call.input, output);

		if (end !== undefined) {
			return end;
		}

		message.content.push({
			type: "tool-result",
			toolCallId: call.id,
			toolName: call.name,
			output: { type: output.isError ? "error-text" : "text", value: output.text },
		});
	}

	return message;
}

// After an abort, a call would act in a new game or a stopped run, so it
// doesn't run. An abort waits for the call in progress, so no Lua command is
// cut off.
export function beforeCall({ signal }: TurnRun): TurnEnd | undefined {
	return signal.aborted ? { aborted: true } : undefined;
}

// Logs a call that ran, and returns the end it brings, if any. Once end_turn
// goes through, it's another player's turn, so no later call runs, and none
// runs past a limit.
export async function afterCall(run: TurnRun, name: string, input: unknown, output: ToolOutput): Promise<TurnEnd | undefined> {
	const { agent, context, signal, actions, tally } = run;
	const { client, logger } = context;

	// The failure is the text the model gets, which says why, such as a
	// game that didn't answer. The message keeps its first line.
	const outcome = output.isError ? `failed: ${output.text.split("\n")[0]}` : "done";

	logger.debug("tool_call", `${name}: ${outcome}`, { player: agent.playerID, tool: name, input, ok: !output.isError, ...(output.isError ? { failure: output.text } : {}) });

	if (name === END_TURN && !output.isError) {
		return { ended: true };
	}

	const limit = actions.has(name) ? countAction(tally, output.isError, context.limits) : undefined;

	if (limit !== undefined) {
		return { limit };
	}

	// A failed call may mean the game stopped answering, and the next call
	// or model call would only fail the same way. The wait ends only when the
	// game answers or the turn's signal aborts.
	if (output.isError && !await waitForGame(client, logger, agent.playerID, signal, context.gameWaitMs)) {
		return { aborted: true };
	}

	return undefined;
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
